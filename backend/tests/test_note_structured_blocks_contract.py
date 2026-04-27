import pytest
from pydantic import ValidationError

from app.schemas.note import NoteChecklistItem, NoteStructuredBlock


def test_note_structured_blocks_accept_notion_lite_types():
    blocks = [
        NoteStructuredBlock(id="heading", type="heading", text="Weekly plan"),
        NoteStructuredBlock(id="paragraph", type="paragraph", text="Review goals"),
        NoteStructuredBlock(id="bullets", type="bullet_list", items=["Read", "Plan"]),
        NoteStructuredBlock(
            id="checks",
            type="checklist",
            items=[NoteChecklistItem(id="item_1", text="Submit report")],
        ),
        NoteStructuredBlock(id="divider", type="divider"),
        NoteStructuredBlock(
            id="image",
            type="image",
            local_path="/tmp/photo.jpg",
            file_type="image/jpeg",
        ),
        NoteStructuredBlock(id="task", type="task_link", task_title="Draft project"),
    ]

    assert [block.type for block in blocks] == [
        "heading",
        "paragraph",
        "bullet_list",
        "checklist",
        "divider",
        "image",
        "task_link",
    ]


def test_note_structured_blocks_reject_incomplete_image_block():
    with pytest.raises(ValidationError):
        NoteStructuredBlock(id="image", type="image")


def test_note_structured_blocks_reject_empty_heading():
    with pytest.raises(ValidationError):
        NoteStructuredBlock(id="heading", type="heading", text=" ")
