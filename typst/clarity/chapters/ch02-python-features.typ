// chapters/ch02-python-features.typ
#import "../theme.typ": note, tip, warning, danger, chapter-intro

= Python Features

#chapter-intro[
  Python rewards the programmer who understands its idioms. This chapter
  captures the fundamentals I reach for most — the patterns that have
  saved me hours of debugging or led me to write code I was still proud
  of a year later.
]

== Functions and Signatures

Python functions are straightforward, but the details matter once your
codebase grows beyond a single file.

=== Keyword-only arguments

```python
def process(data, *, verbose=False, max_retries=3):
    """
    The bare * forces everything after it to be keyword-only.
    Callers cannot pass those arguments positionally.
    """
    for attempt in range(max_retries):
        try:
            return _run(data, verbose=verbose)
        except TransientError:
            if attempt == max_retries - 1:
                raise
```

#tip[
  Use `*` whenever a function has more than two parameters. It makes
  call sites self-documenting: `process(data, verbose=True)` is
  unambiguous, while `process(data, True, 5)` is not.
]

=== Type hints

```python
from typing import Sequence

def flatten(items: Sequence[list[int]]) -> list[int]:
    return [x for sub in items for x in sub]
```

#note[
  Type hints are not enforced at runtime — they are machine-readable
  documentation. Add them to any function called from more than one
  place; tools like `mypy` and your IDE will thank you.
]

== Error Handling

Exceptions in Python carry meaning. Catch the narrowest type you can
actually handle.

```python
# Bad: swallows everything, including bugs
try:
    result = risky_operation()
except Exception:
    result = None

# Good: only handle what you understand
try:
    result = risky_operation()
except ValueError as e:
    log.warning("Invalid input: %s", e)
    result = default_value()
```

#warning[
  Never use a bare `except:` without a type. It catches
  `KeyboardInterrupt`, `SystemExit`, and other signals you almost
  certainly do not want to suppress.
]

#danger[
  Silently returning `None` on failure is one of the most common
  sources of confusing bugs. Either raise, return a sentinel the
  caller checks explicitly, or use a `Result` type pattern.
]

== A Note on Style

Following PEP 8 is not about aesthetics — it is about making your
code readable to others (and to yourself six months later).
Consistency inside a codebase matters more than which specific style
you pick.

A short math detour: the cost of inconsistency in a project with $n$
contributors grows roughly as $O(n^2)$ — every pair of developers
has to reconcile their different mental models.
