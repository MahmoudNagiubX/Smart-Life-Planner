from app.services.context_recommendations import build_time_context_recommendations


def test_morning_recommends_deep_work_and_study_goal():
    items = build_time_context_recommendations(
        local_time_block="morning",
        energy_level="high",
        goals=["study"],
    )

    assert items[0]["task_type"] == "deep_work_study"
    assert any(item["preference_match"] for item in items)
    assert any(item["task_type"] == "study_session" for item in items)


def test_night_recommends_low_cognitive_load():
    items = build_time_context_recommendations(
        local_time_block="night",
        energy_level="medium",
        goals=[],
    )

    assert items[0]["task_type"] == "shutdown_low_load"
    assert all(item["suggested_energy"] in {"low", "medium"} for item in items)


def test_unknown_time_block_falls_back_safely():
    items = build_time_context_recommendations(
        local_time_block="unknown",
        energy_level=None,
        goals=["fitness"],
    )

    assert items[0]["task_type"] == "deep_work_study"
    assert any(item["task_type"] == "movement_hydration" for item in items)
