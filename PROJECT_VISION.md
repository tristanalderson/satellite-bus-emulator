# Satellite bus emulator vision

I started this repo to learn more about RTL and the hardware/software boundary. I have a Kria KV260, and I want to pick up where I left off and maybe eventually launch a CubeSat using it.

Designing a PCB to replace the dev kit sounds even cooler. For now, this is a place to experiment and learn; the flight idea is a long-term dream.

## What I want to learn

- Follow a signal from a physical pin through programmable logic, software, telemetry, and a ground station.
- Design and verify RTL, understand timing and clock boundaries, and measure what the hardware actually does.
- Explore the division of work between Linux on the A53, real-time software on the R5, and FPGA logic.
- Learn where working close to hardware still calls for human understanding and judgment, and explore what AI can and cannot do there.

## Possible experiments

These are ideas to try, not commitments:

1. Keep a reproducible platform that boots and exchanges F Prime commands and telemetry.
2. Add a small timestamped event-capture peripheral, simulate its failure cases, and expose its measurements to F Prime.
3. Emulate a satellite subsystem with realistic timing, faults, and observable responses. Choose the interface after the first experiment.
4. Try a bounded R5 task and measure how it behaves when Linux is busy or restarted.
5. Design a custom K26 carrier with accessible debug, power measurement, and the interfaces the experiments actually need.

The order and scope can change as I learn more.

## If the flight dream becomes a mission

There's a lot between getting this working on my desk and flying it. If I get that far, I'll need to figure out the mission, power, heat, radiation, recovery, communications, testing, and launch constraints before choosing flight hardware. For now the KV260 and any first carrier are for development.

## Ideas and open questions

- Which satellite bus or subsystem would be most fun to emulate first?
- What timing or reliability question would be most useful to measure?
- What interfaces and recovery features should a first carrier expose?
- What would a small, achievable first mission actually do?
