import bisect

class RangeDict:
    def __init__(self, ranges=None):
        """
        Initialize the RangeDict.

        ranges: optional list of (range_key, value) or dict {range_key: value}.
        range_key can be:
          - (start, end) tuple
          - range object
          - single int (treated as (n, n))
          - (n,) tuple (treated as (n, n))
        """
        self._ranges = []   # sorted list of (start, end, value)
        self._starts = []   # parallel list of start values
        self._map = {}      # mapping from (start,end) -> value

        if ranges:
            if isinstance(ranges, dict):
                for rng, value in ranges.items():
                    self[rng] = value
            else:
                for rng, value in ranges:
                    self[rng] = value

    def _make_range(self, rng):
        """Normalize input into (start, end)."""
        if isinstance(rng, range):
            start, end = rng.start, rng.stop - 1
        elif isinstance(rng, tuple):
            if len(rng) == 1:  # (n,) -> (n, n)
                start = end = rng[0]
            elif len(rng) == 2:  # (start, end)
                start, end = rng
            else:
                raise ValueError("tuple must be (n,) or (start,end)")
        elif isinstance(rng, int):  # single int -> (n, n)
            start = end = rng
        else:
            raise TypeError("range key must be int, tuple, or range")
        if start > end:
            raise ValueError("start must be <= end")
        return start, end

    def add(self, rng, value):
        """Add a new range with overlap check."""
        start, end = self._make_range(rng)
        idx = bisect.bisect_right(self._starts, start)

        # Check overlap with previous range
        if idx > 0:
            prev_start, prev_end, _ = self._ranges[idx - 1]
            if start <= prev_end:
                raise ValueError("New range overlaps with previous range")
        # Check overlap with next range
        if idx < len(self._ranges):
            next_start, next_end, _ = self._ranges[idx]
            if end >= next_start:
                raise ValueError("New range overlaps with next range")

        self._ranges.insert(idx, (start, end, value))
        self._starts.insert(idx, start)
        self._map[(start, end)] = value

    # Dict-like assignment
    def __setitem__(self, key, value):
        self.add(key, value)

    # Dict-like lookup by integer
    def __getitem__(self, key):
        if isinstance(key, (tuple, range)):  
            raise KeyError("Use get_range() to retrieve by range key")
        idx = bisect.bisect_right(self._starts, key) - 1
        if idx >= 0:
            start, end, value = self._ranges[idx]
            if start <= key <= end:
                return value
        raise KeyError(key)

    # Lookup by contained integer
    def get(self, key, default=None):
        try:
            return self[key]
        except KeyError:
            return default

    # Lookup by exact range key
    def get_range(self, rng, default=None):
        try:
            start, end = self._make_range(rng)
            return self._map[(start, end)]
        except KeyError:
            return default

    # Dict-like iteration
    def items(self):
        for (start, end, value) in self._ranges:
            yield (start, end), value

    def keys(self):
        for (start, end, _) in self._ranges:
            yield (start, end)

    def values(self):
        for (_, _, value) in self._ranges:
            yield value

    def __iter__(self):
        return self.keys()

    def __len__(self):
        return len(self._ranges)

    def __contains__(self, key):
        """Check if a range is contained within any existing range."""
        try:
            start, end = self._make_range(key)
            # Check if the range [start, end] is contained within any existing range
            for range_start, range_end, _ in self._ranges:
                if range_start <= start <= range_end and range_start <= end <= range_end:
                    return True
            return False
        except Exception:
            return False

    def __repr__(self):
        return f"RangeDict({list(self.items())})"
