from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

from block2python.clients.cli.game_session_demo import DEFAULT_QUEST_ID
from block2python.integration.bridge_stdio import BridgeServer

DEFAULT_TUTOR_CONFIG_PATH = Path(".block2python") / "tutor_config.json"
SUPPORTED_TUTOR_PROVIDERS = frozenset({"template", "stub", "local", "openai_compatible"})


@dataclass(frozen=True, slots=True)
class TutorUserConfig:
    provider: str = "template"
    endpoint_url: str = "https://api.openai.com/v1/chat/completions"
    model: str = "gpt-4o-mini"
    api_key: str = ""
    timeout_sec: float = 30.0
    system_prompt: str | None = None

    def to_dict(self) -> dict[str, object]:
        return {
            "provider": self.provider,
            "endpoint_url": self.endpoint_url,
            "model": self.model,
            "api_key": self.api_key,
            "timeout_sec": self.timeout_sec,
            "system_prompt": self.system_prompt,
        }


class TutorApiRouter:
    """Route JSON requests for the tutor HTTP API."""

    def __init__(
        self,
        *,
        bridge_server: BridgeServer | None = None,
        config_path: Path = DEFAULT_TUTOR_CONFIG_PATH,
    ) -> None:
        self._bridge_server = bridge_server or BridgeServer()
        self._config_path = config_path

    def handle_request(
        self,
        *,
        method: str,
        path: str,
        body: object | None,
    ) -> tuple[int, dict[str, object]]:
        normalized_method = method.upper()
        normalized_path = urlsplit(path).path

        if normalized_method == "GET" and normalized_path == "/api/tutor/config":
            config = load_tutor_user_config(config_path=self._config_path)
            return 200, config.to_dict()

        if normalized_method == "POST" and normalized_path == "/api/tutor/config":
            return self._handle_update_config(body)

        if normalized_method == "POST" and normalized_path == "/api/tutor/reply":
            return self._handle_tutor_reply(body)

        return 404, {
            "error": "Route not found",
            "error_code": "not_found",
        }

    def _handle_update_config(self, body: object | None) -> tuple[int, dict[str, object]]:
        if body is None:
            body = {}

        try:
            current = load_tutor_user_config(config_path=self._config_path)
            updated = tutor_user_config_from_payload(body, base=current)
            save_tutor_user_config(updated, config_path=self._config_path)
        except ValueError as exc:
            return 400, {"error": str(exc), "error_code": "invalid_config"}
        except OSError as exc:
            return 500, {"error": str(exc), "error_code": "io_error"}

        return 200, updated.to_dict()

    def _handle_tutor_reply(self, body: object | None) -> tuple[int, dict[str, object]]:
        if body is None:
            body = {}

        try:
            config = load_tutor_user_config(config_path=self._config_path)
            payload = prepare_tutor_reply_payload(body, config=config)
        except ValueError as exc:
            return 400, {"error": str(exc), "error_code": "invalid_request"}

        bridge_response = self._bridge_server.handle_request({"command": "tutor_reply", "payload": payload})
        if bool(bridge_response.get("ok", False)):
            tutor_payload = bridge_response.get("tutor")
            if isinstance(tutor_payload, dict):
                return 200, tutor_payload
            return 500, {
                "error": "Bridge response missing tutor payload",
                "error_code": "internal_error",
            }

        error_message = bridge_response.get("error")
        if isinstance(error_message, str) and error_message:
            return 400, {"error": error_message, "error_code": "invalid_request"}

        return 500, {
            "error": "Bridge returned an unknown error",
            "error_code": "internal_error",
        }


def load_tutor_user_config(*, config_path: Path = DEFAULT_TUTOR_CONFIG_PATH) -> TutorUserConfig:
    if not config_path.exists():
        return TutorUserConfig()

    try:
        raw = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return TutorUserConfig()

    try:
        return tutor_user_config_from_payload(raw, base=TutorUserConfig())
    except ValueError:
        return TutorUserConfig()


def save_tutor_user_config(config: TutorUserConfig, *, config_path: Path = DEFAULT_TUTOR_CONFIG_PATH) -> None:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(config.to_dict(), ensure_ascii=False, indent=2) + "\n"
    config_path.write_text(payload, encoding="utf-8")


def tutor_user_config_from_payload(
    payload: object,
    *,
    base: TutorUserConfig | None = None,
) -> TutorUserConfig:
    if not isinstance(payload, dict):
        raise ValueError("Tutor config payload must be a JSON object")

    current = base or TutorUserConfig()
    source = dict(payload)
    options = _extract_provider_options(source)

    provider_raw = _pick_config_value(source, options, "provider", current.provider)
    if not isinstance(provider_raw, str) or not provider_raw.strip():
        raise ValueError("Tutor config provider must be a non-empty string")
    provider = provider_raw.strip().lower()
    if provider not in SUPPORTED_TUTOR_PROVIDERS:
        supported = ", ".join(sorted(SUPPORTED_TUTOR_PROVIDERS))
        raise ValueError(f"Unsupported tutor provider: {provider}. Supported: {supported}")

    endpoint_url = _parse_optional_str(
        _pick_config_value(source, options, "endpoint_url", current.endpoint_url),
        field_name="endpoint_url",
    )
    model = _parse_optional_str(
        _pick_config_value(source, options, "model", current.model),
        field_name="model",
    )
    api_key = _parse_optional_str(
        _pick_config_value(source, options, "api_key", current.api_key),
        field_name="api_key",
    )

    timeout_sec = _pick_config_value(source, options, "timeout_sec", current.timeout_sec)
    timeout_sec = _parse_positive_float(timeout_sec, field_name="timeout_sec")

    system_prompt_raw = _pick_config_value(source, options, "system_prompt", current.system_prompt)
    if system_prompt_raw is not None and not isinstance(system_prompt_raw, str):
        raise ValueError("Tutor config system_prompt must be a string or null")

    return TutorUserConfig(
        provider=provider,
        endpoint_url=endpoint_url,
        model=model,
        api_key=api_key,
        timeout_sec=timeout_sec,
        system_prompt=system_prompt_raw,
    )


def prepare_tutor_reply_payload(
    payload: object,
    *,
    config: TutorUserConfig,
) -> dict[str, object]:
    if not isinstance(payload, dict):
        raise ValueError("Tutor request payload must be a JSON object")

    source = dict(payload)
    if "payload" in source:
        nested = source.get("payload")
        if not isinstance(nested, dict):
            raise ValueError("Tutor request payload.payload must be a JSON object")
        source = dict(nested)

    provider_raw = source.get("provider")
    if provider_raw is None:
        provider = config.provider
    elif isinstance(provider_raw, str) and provider_raw.strip():
        provider = provider_raw.strip().lower()
    else:
        raise ValueError("Tutor request provider must be a non-empty string")

    if provider not in SUPPORTED_TUTOR_PROVIDERS:
        supported = ", ".join(sorted(SUPPORTED_TUTOR_PROVIDERS))
        raise ValueError(f"Unsupported tutor provider: {provider}. Supported: {supported}")

    source["provider"] = provider

    if provider == "openai_compatible" or provider == "local":
        options_raw = source.get("provider_options")
        if options_raw is None:
            options_raw = {}
        if not isinstance(options_raw, dict):
            raise ValueError("Tutor request provider_options must be a JSON object")

        options = dict(options_raw)
        options.setdefault("endpoint_url", config.endpoint_url)
        options.setdefault("model", config.model)
        options.setdefault("timeout_sec", config.timeout_sec)
        if config.api_key:
            options.setdefault("api_key", config.api_key)
        if config.system_prompt:
            options.setdefault("system_prompt", config.system_prompt)
        source["provider_options"] = options

    return source


def build_http_handler(router: TutorApiRouter) -> type[BaseHTTPRequestHandler]:
    class TutorHttpRequestHandler(BaseHTTPRequestHandler):
        _router = router

        def do_GET(self) -> None:  # noqa: N802
            self._dispatch("GET")

        def do_POST(self) -> None:  # noqa: N802
            self._dispatch("POST")

        def log_message(self, format: str, *args: object) -> None:
            _ = format
            _ = args

        def _dispatch(self, method: str) -> None:
            body: object | None = None
            if method == "POST":
                body, error = _parse_request_body(self)
                if error is not None:
                    self._send_json(400, {"error": error, "error_code": "invalid_json"})
                    return

            status, payload = self._router.handle_request(method=method, path=self.path, body=body)
            self._send_json(status, payload)

        def _send_json(self, status: int, payload: dict[str, object]) -> None:
            encoded = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

    return TutorHttpRequestHandler


def _parse_request_body(handler: BaseHTTPRequestHandler) -> tuple[object | None, str | None]:
    content_length_raw = handler.headers.get("Content-Length", "0")
    try:
        content_length = max(int(content_length_raw), 0)
    except ValueError:
        return None, "Invalid Content-Length"

    raw = handler.rfile.read(content_length)
    if not raw:
        return {}, None

    try:
        decoded = raw.decode("utf-8")
    except UnicodeDecodeError:
        return None, "Request body must be UTF-8"

    try:
        parsed = json.loads(decoded)
    except json.JSONDecodeError as exc:
        return None, f"Invalid JSON: {exc.msg}"

    return parsed, None


def run_tutor_http_server(
    *,
    host: str,
    port: int,
    router: TutorApiRouter,
) -> None:
    handler_cls = build_http_handler(router)
    server = ThreadingHTTPServer((host, port), handler_cls)
    with server:
        server.serve_forever()


def _extract_provider_options(source: dict[str, object]) -> dict[str, object]:
    options_raw = source.get("provider_options")
    if isinstance(options_raw, dict):
        return dict(options_raw)
    return {}


def _pick_config_value(
    source: dict[str, object],
    options: dict[str, object],
    key: str,
    default: object,
) -> object:
    if key in source:
        return source[key]
    if key in options:
        return options[key]
    return default


def _parse_optional_str(value: object, *, field_name: str) -> str:
    if not isinstance(value, str):
        raise ValueError(f"Tutor config {field_name} must be a string")
    return value.strip()


def _parse_positive_float(value: object, *, field_name: str) -> float:
    if isinstance(value, bool):
        raise ValueError(f"Tutor config {field_name} must be a positive number")
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"Tutor config {field_name} must be a positive number") from exc
    if parsed <= 0:
        raise ValueError(f"Tutor config {field_name} must be a positive number")
    return parsed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the Block2Python tutor HTTP API server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--config-path", type=Path, default=DEFAULT_TUTOR_CONFIG_PATH)
    parser.add_argument("--levels-dir", type=Path, default=Path("assets/levels"))
    parser.add_argument("--game-content-dir", type=Path, default=Path("assets/game_content"))
    parser.add_argument("--teaching-skills-dir", type=Path, default=Path("assets/teaching_skills"))
    parser.add_argument("--quest-id", default=DEFAULT_QUEST_ID)
    parser.add_argument("--use-stub-judge", action="store_true")
    args = parser.parse_args(argv)

    bridge_server = BridgeServer(
        levels_dir=args.levels_dir,
        game_content_dir=args.game_content_dir,
        teaching_skills_dir=args.teaching_skills_dir,
        quest_id=args.quest_id,
        use_stub_judge=args.use_stub_judge,
    )
    router = TutorApiRouter(bridge_server=bridge_server, config_path=args.config_path)
    run_tutor_http_server(host=args.host, port=args.port, router=router)
    return 0


__all__ = [
    "DEFAULT_TUTOR_CONFIG_PATH",
    "SUPPORTED_TUTOR_PROVIDERS",
    "TutorApiRouter",
    "TutorUserConfig",
    "build_http_handler",
    "load_tutor_user_config",
    "main",
    "prepare_tutor_reply_payload",
    "run_tutor_http_server",
    "save_tutor_user_config",
    "tutor_user_config_from_payload",
]


if __name__ == "__main__":
    raise SystemExit(main())
