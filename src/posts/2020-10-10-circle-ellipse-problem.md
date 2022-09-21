---
title: "The Circle-Ellipse Problem"
date: 2020-10-10
author: kotatsuyaki (Ming-Long Huang)
---

```
Ellipse
 + strechX(f)
Circle: Ellipse
 + strechX(f) <= Does not make sense!
```

Suppose that we represent the relationship between circles and ellipses
using *inheritance*.

-   Ellipses is *more general* in that it's a superset of the circles.

-   For a ellipse to be a circle, it must have major and minor axes with
    equal lengths, so it's *stricter*.

Hence, `Circle` shoule be a subtype of `Ellipse`. Now if we proceed to
add a method `Ellipse.stretchX`, then since `Circle` also has this
problem, it'd change a circle into something that's no longer a circle,
since it breaks the invariant of circles mentioned above.

<!-- more -->

Possible solutions include:

-   Return success / failure status, or throw exceptions.

-   Allow `Circle.strechX` to change $x$ and $y$ at the same time (i.e.
    weaken the contract).

-   Cast to parent class `Ellipse`.

-   Return streched shape (the functional approach).

-   Introduce new subtype `MutableEllipse` (i.e. factor out modifiers)

-   Introduce new abstract base class `EllipseOrCircle`.

In we may think that a circle **is-an** ellipse, which also applies to
the person-prisoner case.

```
Person
 + walkNorth(i)
Prisoner: Person
 + walkNorth(i) <= Does not make sense!
```

Now if we decide to rename `Person` to `FreePerson`, then it's clear
that a prisoner is **not** a free person. The inheritance makes no
sense. This tells us that inheritance shouldn't be used when the
**subtype has restrictions on the freedom** assumed in the base class.,
which is exactly why many people advocate to “prefer composition over
inheritance”.
