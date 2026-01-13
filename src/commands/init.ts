import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import inquirer from "inquirer";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface InitOptions {
  output: string;
  global?: boolean;
  install?: boolean;
}

function getTemplatePath(): string {
  // When running from dist/, templates is at ../templates
  // When running from source, templates is at ../../templates
  const distPath = path.join(__dirname, "..", "templates", "statusline.sh");
  const srcPath = path.join(__dirname, "..", "..", "templates", "statusline.sh");

  if (fs.existsSync(distPath)) {
    return distPath;
  }
  if (fs.existsSync(srcPath)) {
    return srcPath;
  }
  throw new Error("Could not find statusline.sh template");
}

function getClaudeSettingsPath(global: boolean, projectDir: string): string {
  if (global) {
    const homeDir = process.env.HOME || process.env.USERPROFILE || "~";
    return path.join(homeDir, ".claude", "settings.json");
  }
  return path.join(projectDir, ".claude", "settings.json");
}

function ensureDirectory(filePath: string): void {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function updateSettings(
  settingsPath: string,
  statuslineCommand: string
): void {
  let settings: Record<string, unknown> = {};

  if (fs.existsSync(settingsPath)) {
    try {
      const content = fs.readFileSync(settingsPath, "utf-8");
      settings = JSON.parse(content);
    } catch {
      console.log("  Warning: Could not parse existing settings.json, creating new one");
    }
  }

  settings.statusLine = {
    type: "command",
    command: statuslineCommand,
    padding: 0,
  };

  ensureDirectory(settingsPath);
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
}

export async function init(options: InitOptions): Promise<void> {
  console.log("\n  Claude Code Statusline Installer\n");

  const isGlobal = options.global || false;
  const shouldInstall = options.install !== false;
  const projectDir = process.cwd();

  // Determine output path
  let outputPath: string;
  if (isGlobal) {
    const homeDir = process.env.HOME || process.env.USERPROFILE || "~";
    outputPath = path.join(homeDir, ".claude", "statusline.sh");
  } else {
    outputPath = path.resolve(projectDir, options.output);
  }

  // Check if script already exists
  if (fs.existsSync(outputPath)) {
    const { overwrite } = await inquirer.prompt([
      {
        type: "confirm",
        name: "overwrite",
        message: `Statusline script already exists at ${outputPath}. Overwrite?`,
        default: false,
      },
    ]);

    if (!overwrite) {
      console.log("  Installation cancelled.\n");
      return;
    }
  }

  // Confirm installation location
  const locationLabel = isGlobal ? "global (~/.claude/)" : "project (./.claude/)";
  console.log(`  Installing to: ${locationLabel}`);
  console.log(`  Script path: ${outputPath}\n`);

  const { confirm } = await inquirer.prompt([
    {
      type: "confirm",
      name: "confirm",
      message: "Proceed with installation?",
      default: true,
    },
  ]);

  if (!confirm) {
    console.log("  Installation cancelled.\n");
    return;
  }

  // Read the template
  const templatePath = getTemplatePath();
  const scriptContent = fs.readFileSync(templatePath, "utf-8");

  // Write the statusline script
  ensureDirectory(outputPath);
  fs.writeFileSync(outputPath, scriptContent);
  fs.chmodSync(outputPath, "755");
  console.log(`  Created statusline script: ${outputPath}`);

  // Update settings.json if requested
  if (shouldInstall) {
    const settingsPath = getClaudeSettingsPath(isGlobal, projectDir);
    const statuslineCommand = isGlobal
      ? "~/.claude/statusline.sh"
      : ".claude/statusline.sh";

    updateSettings(settingsPath, statuslineCommand);
    console.log(`  Updated settings: ${settingsPath}`);
  }

  console.log("\n  Installation complete!\n");
  console.log("  Restart Claude Code to see your new statusline.\n");

  // Check for jq
  const { execSync } = await import("child_process");
  try {
    execSync("command -v jq", { stdio: "ignore" });
  } catch {
    console.log("  Note: 'jq' is not installed. Some features will be limited.");
    console.log("  Install jq for full functionality:");
    console.log("    macOS: brew install jq");
    console.log("    Linux: apt-get install jq / yum install jq\n");
  }
}
