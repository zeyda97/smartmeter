from datetime import datetime, timezone


class TimeProvider:
    # Initialize default root to the current time in seconds since epoch (UTC)
    default_root = int(datetime.now(timezone.utc).timestamp())
    config = None  # Equivalent to Scala's Option[Long]

    @property
    def root(self):
        # Lazy evaluation for root
        return self.config if self.config is not None else self.default_root

    def time(self):
        # Current time in seconds since epoch (UTC)
        current_time = int(datetime.now(timezone.utc).timestamp())
        # Compute delta
        delta = current_time - self.root
        # Compute adjusted time
        return self.root + (delta * 60 * 15)



if __name__ == "__main__":
    provider = TimeProvider()
    
    
    # Appeler la méthode time()
    adjusted_time = provider.time()
    print(f"Adjusted time (in seconds since epoch): {adjusted_time}")
