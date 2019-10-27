# insightful/cockroachdb

This is a work-in-progress repository for building a multi-arch container to run [Cockroach DB](https://www.cockroachlabs.com/) on ARM32/64.

It currently does not build on ARM32 due to not following [these instructions](https://www.cockroachlabs.com/blog/run-cockroachdb-on-a-raspberry-pi/) to the letter.

## Roadmap

- [ ] sane startup scripts (change base image to `alpine-s6`)
- [ ] minimal multi-step build
- [ ] fix ARM32 build
- [x] base scaffolding