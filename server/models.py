"""Parts-list request/response models."""
from __future__ import annotations

from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class CordHolePos(str, Enum):
    left = "left"
    middle = "middle"
    right = "right"


class JoinSex(str, Enum):
    male = "male"
    female = "female"


class EdgePart(BaseModel):
    kind: Literal["edge"] = "edge"
    qty: int = Field(1, ge=1, le=20)
    length: float = Field(50.0, gt=0, le=500)
    # 0 none, 1 start, 2 both (sex), 3 finish, 4 both female
    edge_join_ends: int = Field(0, ge=0, le=4)
    edge_join_sex: JoinSex = JoinSex.male
    # Deprecated alias — if set and edge_join_ends left default, used as ends
    stem_gripper_sides: int | None = Field(None, ge=0, le=4)
    cornerpiecenum: int = Field(0, ge=0, le=3)
    cord_hole: bool = False
    cord_hole_inner_d: float = Field(6.0, gt=0, le=40)
    cord_hole_pos: CordHolePos = CordHolePos.middle
    cord_under: bool = False
    cord_under_gap_len: float = Field(20.0, gt=0, le=400)
    lid_ingress: bool = False
    ingress_depth: float = Field(30.0, gt=0, le=200)
    ingress_length: float = Field(40.0, gt=0, le=400)
    ingress_remove_right_rim: bool = False

    @model_validator(mode="after")
    def resolve_join_alias(self):
        if self.stem_gripper_sides is not None and self.edge_join_ends == 0:
            object.__setattr__(self, "edge_join_ends", self.stem_gripper_sides)
        return self

    @staticmethod
    def _join_on(ends: int, start: bool) -> bool:
        if ends == 4:
            return True
        if start:
            return ends in (1, 2)
        return ends in (2, 3)

    @staticmethod
    def _end_clearance(ends: int, cornerpiecenum: int, start: bool) -> float:
        grip = 15.0 if EdgePart._join_on(ends, start) else 0.0
        corn_on = (
            cornerpiecenum in (1, 2) if start else cornerpiecenum in (2, 3)
        )
        return grip + (15.0 if corn_on else 0.0)

    @model_validator(mode="after")
    def addon_restrictions(self):
        ends = self.edge_join_ends
        clear_s = self._end_clearance(ends, self.cornerpiecenum, True)
        clear_f = self._end_clearance(ends, self.cornerpiecenum, False)
        mw = 14.0

        if self.lid_ingress:
            bay = self.ingress_length + 2 * (10.8 + 5.0)  # edge_top_width
            need = bay + clear_s + clear_f + 2 * mw
            if need > self.length:
                raise ValueError(
                    f"ingress_length {self.ingress_length} (+miters) overlaps end "
                    f"joins/corners or exceeds length {self.length}"
                )

        if self.cord_under and self.cord_under_gap_len >= self.length - clear_s - clear_f:
            raise ValueError("cord_under_gap_len must fit between end accessories")

        if self.cord_hole:
            frac = {"left": 1 / 3, "middle": 0.5, "right": 2 / 3}[self.cord_hole_pos.value]
            if not self.lid_ingress:
                hz = self.length * frac
                hr = (self.cord_hole_inner_d + self.cord_hole_inner_d / 3) / 2
                if hz - hr < clear_s or hz + hr > self.length - clear_f:
                    raise ValueError(
                        "cord hole cannot pass corner or end join zones"
                    )
        return self


class CornerPart(BaseModel):
    kind: Literal["corner"] = "corner"
    qty: int = Field(1, ge=1, le=16)
    # Each assembly = pegged pair (holes half + pegs half)


class PartsList(BaseModel):
    name: str = Field("aquarium-lid-plate", min_length=1, max_length=80)
    parts: list[EdgePart | CornerPart]

    @field_validator("parts")
    @classmethod
    def non_empty(cls, v):
        if not v:
            raise ValueError("parts list must contain at least one item")
        return v


class JobStatus(BaseModel):
    job_id: str
    status: str
    message: str = ""
    stl_count: int = 0
    gcode_3mf: str | None = None
    download_url: str | None = None
    plate_ok: bool = True
    bom: dict = Field(default_factory=dict)


class PrintRequest(BaseModel):
    # Optional override; otherwise env settings
    bambu_ip: str | None = None
    bambu_access_code: str | None = None
    bambu_serial: str | None = None


class PrinterStatus(BaseModel):
    configured: bool
    ip: str = ""
    serial: str = ""
    reachable: bool | None = None
    detail: str = ""
