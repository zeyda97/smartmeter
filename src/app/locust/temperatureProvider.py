import math
from datetime import datetime


class TemperatureProvider:

    @staticmethod
    def temperature(date: datetime, rnd: float) -> float:
        # Annual variation
        annual_variation = -22.0 * math.cos((2 * math.pi * (date.timetuple().tm_yday - 1)) / 365)

        # Daily variation
        daily_variation = 1.0 * math.cos((2 * math.pi * (date.weekday() - 1)) / 6)

        # Hourly variation
        hourly_variation = -5.0 * math.cos((2 * math.pi * date.hour) / 23)

        # Random variation
        rnd_variation = 2.0 * rnd

        return annual_variation + daily_variation + hourly_variation + rnd_variation



if __name__ == "__main__":
    current_time = datetime.now()
    random_factor = 0.5  # Exemple de facteur aléatoire
    temp = TemperatureProvider.temperature(current_time, random_factor)
    print(f"Temperature: {temp:.2f}")
