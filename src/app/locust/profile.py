from typing import Protocol
from enum import Enum


class DayOfWeek(Enum):
    MONDAY = 0
    TUESDAY = 1
    WEDNESDAY = 2
    THURSDAY = 3
    FRIDAY = 4
    SATURDAY = 5
    SUNDAY = 6


class Profile(Protocol):
    def demand_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        ...

    def voltage_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        ...


class DefaultProfile(Profile):
    def demand_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        return abs(rnd_value * (hash(usage_point_pk) % 1000))

    def voltage_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        return rnd_value * 2 + hour_in_day / 2.4 + 113


class RandnProfile(Profile):
    def demand_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        return rnd_value

    def voltage_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        return rnd_value


class ProfileByUsagePoint(Profile):
    def __init__(self):
        self.case_nb = 10

    def case_fn(self, usage_point_pk: str) -> int:
        return abs(hash(usage_point_pk)) % self.case_nb

    def demand_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        case = self.case_fn(usage_point_pk)
        return abs(rnd_value * (hash(usage_point_pk) % (100 + case * 50)))

    def voltage_at_day_and_hour(self, usage_point_pk: str, day_in_week: DayOfWeek, hour_in_day: int, rnd_value: float) -> float:
        case = self.case_fn(usage_point_pk)
        return rnd_value * 2 + hour_in_day / 2.4 + 100 + case
