# StreamWatch UI Claude Code Agents

This folder contains StreamWatch UI specific Claude Code agents.

Agents:
- sw-manager: coordinator, discovery first, delegates to implementers and gatekeeper
- sw-gatekeeper: ship gate, reviews proof and invariants, outputs SHIP or NOT SHIP
- sw-flutter: primary Flutter/Dart implementer for UI work
- sw-test-runner: runs flutter analyze + flutter test, fixes failures with minimal diffs

Usage pattern:
1) Start with sw-manager.
2) sw-manager delegates implementation to sw-flutter.
3) sw-test-runner runs the proof commands and fixes failures.
4) sw-gatekeeper reviews and decides SHIP or NOT SHIP.

Note: For Go API or Python worker changes, use the agents in `streamwatch-api/.claude/agents/`.
