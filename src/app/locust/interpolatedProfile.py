import numpy as np
from scipy.interpolate import interp1d
from enum import IntEnum
import random

# Définition des jours de la semaine
class DayOfWeek(IntEnum):
    MONDAY = 0
    TUESDAY = 1
    WEDNESDAY = 2
    THURSDAY = 3
    FRIDAY = 4
    SATURDAY = 5
    SUNDAY = 6

# Classe de base pour le profil interpolé
class InterpolatedProfile:
    def __init__(self, week_values, weekend_values):
        self.hours = np.arange(0, 24, 3)  # Plage d'heures : 0h à 24h par pas de 3h
        print(self.hours)
        self.week_values = week_values
        self.weekend_values = weekend_values

        # Création des interpolateurs
        self.week_interpolator = interp1d(self.hours, self.week_values, kind='linear', fill_value="extrapolate")
        self.weekend_interpolator = interp1d(self.hours, self.weekend_values, kind='linear', fill_value="extrapolate")

    @staticmethod
    def bias(usage_point_pk, day_in_week, hour_in_day, rnd_value, range_value):
        """Calcule un biais systématique."""
        hash_factor = ((hash(usage_point_pk) + day_in_week + hour_in_day) % 20) / 20 - 0.5
        return 0.4 * range_value * (rnd_value + hash_factor)

    def value_at_day_and_hour(self, usage_point_pk, day_in_week, hour_in_day, rnd_value):
        """Calcule la valeur interpolée pour un jour et une heure donnés."""
        is_weekend = day_in_week in {DayOfWeek.SATURDAY, DayOfWeek.SUNDAY}
        interpolator = self.weekend_interpolator if is_weekend else self.week_interpolator
        range_value = max(self.week_values) - min(self.week_values) if not is_weekend else max(self.weekend_values) - min(self.weekend_values)
        return abs(self.bias(usage_point_pk, day_in_week, hour_in_day, rnd_value, range_value) + interpolator(hour_in_day))

# Profils spécifiques
class ConsumerInterpolatedProfile(InterpolatedProfile):
    def __init__(self):
        super().__init__(
            week_values=[100.0, 100.0, 80.0, 50.0, 60.0, 80.0, 90.0, 115.0],
            weekend_values=[100.0, 100.0, 80.0, 90.0, 80.0, 90.0, 115.0, 90.0]
        )

class BusinessInterpolatedProfile(InterpolatedProfile):
    def __init__(self):
        super().__init__(
            week_values=[60.0, 80.0, 160.0, 280.0, 300.0, 290.0, 180.0, 80.0],
            weekend_values=[100.0, 80.0, 70.0, 70.0, 60.0, 70.0, 80.0, 90.0]
        )

class IndustryInterpolatedProfile(InterpolatedProfile):
    def __init__(self):
        super().__init__(
            week_values=[3000.0, 3000.0, 3200.0, 3300.0, 3200.0, 3300.0, 3100.0, 3000.0],
            weekend_values=[2700.0, 2700.0, 2750.0, 2800.0, 2800.0, 2850.0, 2750.0, 2700.0]
        )

# Gestionnaire de profils
class InterpolatedProfileByUsagePoint:
    def __init__(self):
        self.consumer_profile = ConsumerInterpolatedProfile()
        self.business_profile = BusinessInterpolatedProfile()
        self.industry_profile = IndustryInterpolatedProfile()

    def get_profile_type(self, usage_point_pk):
        """Détermine le type de profil selon la clé usage_point_pk."""
        case_number = abs(hash(usage_point_pk)) % 10
        if case_number in {0, 1, 2}:
            return self.business_profile
        elif case_number in {3, 4}:
            return self.industry_profile
        else:
            return self.consumer_profile

    def demand_at_day_and_hour(self, usage_point_pk, day_in_week, hour_in_day, rnd_value):
        profile = self.get_profile_type(usage_point_pk)
        return profile.value_at_day_and_hour(usage_point_pk, day_in_week, hour_in_day, rnd_value)

    def voltage_at_day_and_hour(self, usage_point_pk, day_in_week, hour_in_day, rnd_value):
        profile = self.get_profile_type(usage_point_pk)
        return profile.value_at_day_and_hour(usage_point_pk, day_in_week, hour_in_day, rnd_value)

# Exemple d'utilisation
if __name__ == "__main__":
    interpolator = InterpolatedProfileByUsagePoint()

    usage_point_pk = "12345"
    day_in_week = DayOfWeek.MONDAY
    hour_in_day = 10
    rnd_value = np.random.random()

    demand = interpolator.demand_at_day_and_hour(usage_point_pk, day_in_week, hour_in_day, rnd_value)
    voltage = interpolator.voltage_at_day_and_hour(usage_point_pk, day_in_week, hour_in_day, rnd_value)

    print(f"Demand: {demand:.2f}, Voltage: {voltage:.2f}")
