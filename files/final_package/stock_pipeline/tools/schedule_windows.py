"""
tools/schedule_windows.py
=========================
Creates a Windows Task Scheduler task that runs the pipeline
every Monday at 7:00 AM automatically.

Usage (run once as Administrator):
  python tools/schedule_windows.py --install
  python tools/schedule_windows.py --remove
  python tools/schedule_windows.py --status

Cline: run this on the gateway/server machine after the pipeline
is validated and working manually.
"""

import sys
import subprocess
import argparse
from pathlib import Path

TASK_NAME = "SAP_PowerBI_Weekly_Refresh"


def install(python_path: str, project_path: str):
    """Register the weekly task in Windows Task Scheduler."""

    script = Path(project_path) / "main.py"
    log    = Path(project_path) / "logs" / "scheduler.log"

    # Build the XML task definition
    xml = f"""<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>SAP HANA to Power BI weekly data refresh — runs every Monday 7:00 AM</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2024-01-01T07:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByWeek>
        <WeeksInterval>1</WeeksInterval>
        <DaysOfWeek>
          <Monday />
        </DaysOfWeek>
      </ScheduleByWeek>
    </CalendarTrigger>
  </Triggers>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{python_path}</Command>
      <Arguments>{script} >> "{log}" 2>&amp;1</Arguments>
      <WorkingDirectory>{project_path}</WorkingDirectory>
    </Exec>
  </Actions>
</Task>"""

    xml_path = Path(project_path) / "task.xml"
    xml_path.write_text(xml, encoding="utf-16")

    result = subprocess.run(
        ["schtasks", "/Create", "/TN", TASK_NAME, "/XML", str(xml_path), "/F"],
        capture_output=True, text=True
    )

    xml_path.unlink()  # clean up temp file

    if result.returncode == 0:
        print(f"✓  Task '{TASK_NAME}' created successfully.")
        print(f"   Runs every Monday at 07:00 AM")
        print(f"   Log: {log}")
    else:
        print(f"✗  Failed to create task:\n{result.stderr}")
        print("   Make sure you are running as Administrator.")
        sys.exit(1)


def remove():
    result = subprocess.run(
        ["schtasks", "/Delete", "/TN", TASK_NAME, "/F"],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f"✓  Task '{TASK_NAME}' removed.")
    else:
        print(f"Task not found or already removed:\n{result.stderr}")


def status():
    result = subprocess.run(
        ["schtasks", "/Query", "/TN", TASK_NAME, "/FO", "LIST"],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(result.stdout)
    else:
        print(f"Task '{TASK_NAME}' not found. Run --install first.")


def main():
    parser = argparse.ArgumentParser(description="Windows Task Scheduler setup")
    parser.add_argument("--install", action="store_true", help="Install the weekly task")
    parser.add_argument("--remove",  action="store_true", help="Remove the task")
    parser.add_argument("--status",  action="store_true", help="Check task status")
    parser.add_argument("--python",  default=sys.executable, help="Path to python.exe")
    parser.add_argument("--project", default=str(Path(__file__).parent.parent.resolve()),
                        help="Path to pipeline project folder")
    args = parser.parse_args()

    if args.install:
        install(args.python, args.project)
    elif args.remove:
        remove()
    elif args.status:
        status()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
