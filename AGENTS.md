# CPU project collaboration rules

## Project continuity

- At the start of a new project conversation, read `md/README.md` and `md/STATUS.md` after this file. Read only the task-relevant architecture or daily documents; do not load the entire history by default.
- Keep `md/STATUS.md` as the concise source of truth for the current baseline and next step.
- At the end of a working day, add or update `md/daily/YYYY-MM-DD.md` with only the completed work, validation result, decisions, unresolved issues, and next first step.
- Keep simulation evidence concise in project summaries, for example: `Test 12 passed; 10 expected stalls; archived.` Do not copy full Vivado console logs into the documentation.
- Update `md/ARCHITECTURE.md` only for durable RTL structure changes and `md/ROADMAP.md` only when priorities or milestones change.

## RTL test maintenance

- When RTL behavior is added or changed, Codex should create or update the directed machine-code program in `vFile/verilog/verilog/inst_data.hex`.
- Codex should also update the test sequence and expected checks inside the `initial` block of `vFile/verilog/verilog/test.sv`.
- The user maintains reusable testbench helpers such as `check_regFile` and `check_memory`. Do not rewrite those tasks unless the user asks, or a task contains a defect that prevents the requested test from working.
- For every generated hex program, report the corresponding RISC-V assembly and the expected register or RAM results.
- Keep each test focused on the feature being verified, end the program with a stable loop such as `jal x0, 0`, and preserve automatic PASS/FAIL checks.
- In memory checks, the `index` argument denotes the internal word-array index `ram[index]`, not a byte address.
- Never expect an unwritten RAM entry to be zero. Before checking that a wrong-path store was suppressed, initialize the target RAM entry to a known sentinel value on the correct path and check that the sentinel remains unchanged.
- When the user provides a screenshot that clearly shows the current directed test passed, and the next planned step is another test, immediately update `inst_data.hex` and the `initial` checks for the next test without waiting for an additional request.
- Before replacing a directed test that the user has confirmed passed, archive its exact machine code under `vFile/verilog/verilog/tests/hex/`, archive its exact `check_regFile`/`check_memory` calls under `vFile/verilog/verilog/tests/expected/`, and record its purpose, assembly behavior, and expected architectural state in `vFile/verilog/verilog/tests/README.md`.
- Treat a test as archived only after its `.hex` file, matching expected-check `.svh` file, and README entry all exist. Do this automatically for every future passing test; do not require the user to request archival again.
