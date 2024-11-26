import math
import numpy as np
import random
from datetime import datetime, timezone
from collections import deque
import struct


class ProviderUtil:
    @staticmethod
    def compute_nb_of_elements(users_per_sec):
        line_transformer = int(np.cbrt(users_per_sec))
        line_nb = int(np.cbrt(line_transformer))
        transformer_nb = max(1, line_transformer // line_nb)
        usage_point_nb = max(1, int(users_per_sec / (line_nb * transformer_nb)))

        return line_nb, transformer_nb, usage_point_nb

    @staticmethod
    def compute_incr(streaming_duration):
        return max(1, 60000 // streaming_duration)


class ConsumerInterpolatedVoltageProvider:
    def __init__(self, slot, users_per_sec, streaming_duration, randomness, prediction_length):
        self.slot = slot
        self.randomness = randomness
        self.prediction_length = prediction_length

        # Calcul des éléments (ligne, transformateurs, points d'usage)
        self.line_nb, self.transformer_nb, self.usage_point_nb = ProviderUtil.compute_nb_of_elements(users_per_sec)
        self.line = self.line_nb
        self.transformer = self.transformer_nb
        self.usage_point = self.usage_point_nb + 1

        # Incrémentation et initialisation
        self.incr = ProviderUtil.compute_incr(streaming_duration)
        self.date = datetime.fromtimestamp(int(datetime.now(timezone.utc).timestamp()), timezone.utc)
        self.tictac = True

        # Données par défaut et initialisation des températures
        self.default_values = [100.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0]
        self.RETURN_TYPE = {"TEMPERATURE": 1, "FORECAST": 2, "VOLTAGE": 3}
        self.return_type = self.RETURN_TYPE["TEMPERATURE"]

        self.temperatures = deque([5.0])
        for _ in range(1, prediction_length):
            self.temperatures.append(self.temperatures[0] + (random.random() - 0.5))

    def temperature(self):
        # Ajoute une température aléatoire entre 15.0 et 25.0
        self.temperatures.append(random.uniform(15.0, 25.0))
        return self.temperatures.popleft()

    def forecast(self):
        return self.temperatures[-1]

    def voltage(self):
        base_voltage = 100.0  # Exemple de valeur fixe (personnalisable)
        adjustment = self.randomness * (random.random() - 0.5)
        temperature_effect = abs(self.temperatures[0] - 5) * 0.08
        return base_voltage + adjustment + temperature_effect - 1

    def increment(self):
        if self.tictac:
            if self.return_type == self.RETURN_TYPE["TEMPERATURE"]:
                self.return_type = self.RETURN_TYPE["FORECAST"]
            else:
                if self.usage_point > self.usage_point_nb:
                    self.usage_point = 1
                    self.transformer += 1
                if self.transformer > self.transformer_nb:
                    self.transformer = 1
                    self.line += 1
                if self.line > self.line_nb:
                    self.line = 1
                    self.return_type = self.RETURN_TYPE["TEMPERATURE"]
                else:
                    self.return_type = self.RETURN_TYPE["VOLTAGE"]
        self.tictac = not self.tictac

    def get_subject(self):
        self.increment()
        if self.return_type == self.RETURN_TYPE["TEMPERATURE"]:
            return ".temperature.data"
        elif self.return_type == self.RETURN_TYPE["FORECAST"]:
            return ".temperature.forecast.12"
        elif self.return_type == self.RETURN_TYPE["VOLTAGE"]:
            return f".voltage.data.{self.point()}"

    def get_payload(self):
        self.increment()
        if self.return_type == self.RETURN_TYPE["TEMPERATURE"]:
            value = self.temperature()
        elif self.return_type == self.RETURN_TYPE["FORECAST"]:
            value = self.forecast()
        elif self.return_type == self.RETURN_TYPE["VOLTAGE"]:
            value = self.voltage()
        self.usage_point += 1
        #return self.encode_payload(self.date, value)
        return {'epoch_time': int(self.date.timestamp()), 'value': value}
        
 
 

    def encode_payload(self, date, value):
        buffer = bytearray()  # Buffer dynamique
        epoch_time = int(date.timestamp())
        buffer.extend(struct.pack(">q", epoch_time))  # Timestamp (8 octets)
        buffer.extend(struct.pack(">f", value))  # Float (4 octets)

        if self.return_type == self.RETURN_TYPE["VOLTAGE"]:
            for default_value in self.default_values:
                buffer.extend(struct.pack(">f", default_value + random.random()))
        return bytes(buffer)

    def point(self):
        return f"{(10 * self.slot) + self.line}.{self.transformer}.{self.usage_point}"

if __name__ == "__main__":
    provider = ConsumerInterpolatedVoltageProvider(
        slot=1,
        users_per_sec=100,
        streaming_duration=60,
        randomness=0.1,
        prediction_length=10
    )

    print("Sujet :", provider.get_subject())
    print("Payload :", provider.get_payload())
