_final: prev: {
  # TEMP (2026-07-26): pandas-stubs test collection breaks under pytest 9
  # (PytestRemovedIn10Warning escalated to error), failing the whole
  # markitdown -> alpaca chain. Skip its tests until nixpkgs bumps the
  # package; remove this after a flake update builds without it.
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (_pyfinal: pyprev: {
        # pythonImportsCheck imports pandas, which only comes in via the
        # (now skipped) test deps — disable it along with the tests.
        pandas-stubs = pyprev.pandas-stubs.overridePythonAttrs (_: {
          doCheck = false;
          pythonImportsCheck = [];
        });
        # TEMP (2026-11-01): wandb 0.31.0 on python3.14 has one flaky
        # signal/exit-code test that fails in the sandbox, breaking the
        # spacy -> kokoro -> alpaca chain. Remove after a flake update.
        wandb = pyprev.wandb.overridePythonAttrs (old: {
          disabledTests =
            (old.disabledTests or [])
            ++ ["test_agent_process_poll_reports_function_system_exit"];
        });
      })
    ];
}
