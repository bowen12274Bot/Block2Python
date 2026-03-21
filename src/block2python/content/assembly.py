from __future__ import annotations

from block2python.contracts import LevelSpec

from .errors import GameContentAssemblyError
from .models import AssembledGameSlice, GameContentBundle, ResolvedChallengeSpec
from .validation import validate_map_routes, validate_nodes, validate_quests


def assemble_game_slice(*, game_content: GameContentBundle, levels: dict[str, LevelSpec]) -> AssembledGameSlice:
    validate_nodes(game_content.nodes, game_content.scenes, game_content.challenges)
    validate_quests(game_content.quests, game_content.nodes)
    validate_map_routes(
        game_content.map_routes,
        game_content.quests,
        game_content.nodes,
        game_content.scenes,
        game_content.challenges,
        levels,
    )

    resolved_challenges: dict[str, ResolvedChallengeSpec] = {}
    for challenge_id, challenge in game_content.challenges.items():
        resolved_levels: list[LevelSpec] = []
        for level_id in challenge.level_ids:
            level = levels.get(level_id)
            if level is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing level_id: {level_id}"
                )
            resolved_levels.append(level)

        toolbox_policy = None
        if challenge.toolbox_policy_id is not None:
            toolbox_policy = game_content.toolbox.get(challenge.toolbox_policy_id)
            if toolbox_policy is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing toolbox_policy_id: {challenge.toolbox_policy_id}"
                )

        battery_policy = None
        if challenge.battery_policy_id is not None:
            battery_policy = game_content.battery_policies.get(challenge.battery_policy_id)
            if battery_policy is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing battery_policy_id: {challenge.battery_policy_id}"
                )

        resolved_challenges[challenge_id] = ResolvedChallengeSpec(
            challenge_id=challenge.challenge_id,
            challenge_type=challenge.challenge_type,
            title=challenge.title,
            levels=tuple(resolved_levels),
            toolbox_policy=toolbox_policy,
            battery_policy=battery_policy,
            metadata=dict(challenge.metadata),
        )

    return AssembledGameSlice(
        quests=dict(game_content.quests),
        nodes=dict(game_content.nodes),
        scenes=dict(game_content.scenes),
        challenges=resolved_challenges,
        map_routes=dict(game_content.map_routes),
        levels=dict(levels),
    )
