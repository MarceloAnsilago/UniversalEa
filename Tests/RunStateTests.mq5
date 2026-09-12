#property strict
// Runs the state suites without input dialogs; no trading calls.
#define OnStart RunGuiStateTests
#define Check CheckGuiStateTests
#define checks checksGuiStateTests
#define failures failuresGuiStateTests
#include "GuiStateTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiSetupStateTests
#define Check CheckGuiSetupStateTests
#define checks checksGuiSetupStateTests
#define failures failuresGuiSetupStateTests
#include "GuiSetupStateTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiRulesStateTests
#define Check CheckGuiRulesStateTests
#define checks checksGuiRulesStateTests
#define failures failuresGuiRulesStateTests
#include "GuiRulesStateTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiManagementStateTests
#define Check CheckGuiManagementStateTests
#define checks checksGuiManagementStateTests
#define failures failuresGuiManagementStateTests
#include "GuiManagementStateTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiMagicTests
#define Check CheckGuiMagicTests
#define checks checksGuiMagicTests
#define failures failuresGuiMagicTests
#include "GuiMagicTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiSetFileTests
#define Check CheckGuiSetFileTests
#define checks checksGuiSetFileTests
#define failures failuresGuiSetFileTests
#include "GuiSetFileTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
#define OnStart RunGuiMergedLayoutTests
#define Check CheckGuiMergedLayoutTests
#define checks checksGuiMergedLayoutTests
#define failures failuresGuiMergedLayoutTests
#include "GuiMergedLayoutTests.mq5"
#undef OnStart
#undef Check
#undef checks
#undef failures
void OnStart()
  {
   RunGuiStateTests();
   RunGuiSetupStateTests();
   RunGuiRulesStateTests();
   RunGuiManagementStateTests();
   RunGuiMagicTests();
   RunGuiSetFileTests();
   RunGuiMergedLayoutTests();
   int total_checks=checksGuiMergedLayoutTests+checksGuiStateTests+checksGuiSetupStateTests+checksGuiRulesStateTests+checksGuiManagementStateTests+checksGuiMagicTests+checksGuiSetFileTests;
   int total_failures=failuresGuiMergedLayoutTests+failuresGuiStateTests+failuresGuiSetupStateTests+failuresGuiRulesStateTests+failuresGuiManagementStateTests+failuresGuiMagicTests+failuresGuiSetFileTests;
   PrintFormat("[RunStateTests] %d checks, %d failures",total_checks,total_failures);
  }
