import { Command } from "commander";
import { init } from "./commands/init.js";

const program = new Command();

program
  .name("claude-code-statusline")
  .description(
    "A minimal, vibrant statusline for Claude Code with context tracking, cost monitoring, and token stats"
  )
  .version("1.0.0");

program
  .command("init")
  .description("Install the statusline to your Claude Code configuration")
  .option(
    "-o, --output <path>",
    "Output path for statusline script",
    "./.claude/statusline.sh"
  )
  .option("--global", "Install to global Claude Code settings (~/.claude/)")
  .option("--no-install", "Generate script only, skip settings.json update")
  .action(init);

program.parse();

if (!process.argv.slice(2).length) {
  program.outputHelp();
}
