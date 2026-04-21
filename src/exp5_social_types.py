"""
Exp5 — Social Types: 4 esperimenti separati
============================================
Exp5a: Baseline (tutti normali)
Exp5b: Tutti aggressivi
Exp5c: Tutti prudenti
Exp5d: Tutti imitatori

Ogni esperimento confronta il throughput, il tempo medio di uscita e la velocità
effettiva a densità costante (200 pedoni, 5 ripetizioni, 1000 step).
"""
import subprocess
import pandas as pd
import os
import shutil
import xml.etree.ElementTree as ET

# Configurazione
NETLOGO_HEADLESS = r"C:\Program Files\NetLogo 7.0.3\NetLogo_Console.exe"
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_NAME = os.path.join(BASE_DIR, "models", "DAI_roundabout.nlogo")
RESULTS_DIR = os.path.join(BASE_DIR, "results", "datasets")
TEMP_DIR = os.path.join(BASE_DIR, "results", "temp")

EXPERIMENTS = {
    "Exp5a_Baseline": {
        "params": {
            "num-pedestrians": [200],
            "social-type-mode": ["none"],
            "Kd": [2.0], "Ks": [1.0], "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5, "steps": 1000,
        "metrics": [
            "throughput-per-tick", "throughput-total",
            "mean-exit-time", "mean [effective-speed] of turtles",
            "phi-max", "phi-stabilization-tick"
        ]
    },
    "Exp5b_Aggressive": {
        "params": {
            "num-pedestrians": [200],
            "social-type-mode": ["all-aggressive"],
            "Kd": [2.0], "Ks": [1.0], "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5, "steps": 1000,
        "metrics": [
            "throughput-per-tick", "throughput-total",
            "mean-exit-time", "mean [effective-speed] of turtles",
            "phi-max", "phi-stabilization-tick"
        ]
    },
    "Exp5c_Prudent": {
        "params": {
            "num-pedestrians": [200],
            "social-type-mode": ["all-prudent"],
            "Kd": [2.0], "Ks": [1.0], "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5, "steps": 1000,
        "metrics": [
            "throughput-per-tick", "throughput-total",
            "mean-exit-time", "mean [effective-speed] of turtles",
            "phi-max", "phi-stabilization-tick"
        ]
    },
    "Exp5d_Imitator": {
        "params": {
            "num-pedestrians": [200],
            "social-type-mode": ["all-imitator"],
            "Kd": [2.0], "Ks": [1.0], "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5, "steps": 1000,
        "metrics": [
            "throughput-per-tick", "throughput-total",
            "mean-exit-time", "mean [effective-speed] of turtles",
            "phi-max", "phi-stabilization-tick"
        ]
    }
}


def create_behavior_space_xml(name, config):
    xml = ET.Element("experiments")
    exp = ET.SubElement(xml, "experiment", name=name,
                        repetitions=str(config["repetitions"]),
                        runMetricsEveryStep="false")
    ET.SubElement(exp, "setup").text = "setup"
    ET.SubElement(exp, "go").text = "go"
    ET.SubElement(exp, "timeLimit", steps=str(config["steps"]))

    for metric in config["metrics"]:
        ET.SubElement(exp, "metric").text = metric

    for var, values in config["params"].items():
        val_set = ET.SubElement(exp, "enumeratedValueSet", variable=var)
        for v in values:
            sv = str(v)
            # NetLogo BehaviorSpace requires string values to be quoted
            if var == "social-type-mode":
                sv = f'"{sv}"'
            ET.SubElement(val_set, "value", value=sv)

    return ET.tostring(xml, encoding="unicode") + "\n"


def run_single_experiment(name, config):
    print(f"\n>>> [{name}] Avvio...")

    os.makedirs(TEMP_DIR, exist_ok=True)
    os.makedirs(RESULTS_DIR, exist_ok=True)

    temp_model_rel = os.path.join("results", "temp", f"{name}.nlogo")
    output_csv_rel = os.path.join("results", "datasets", f"{name}_results.csv")

    temp_model_path = os.path.join(BASE_DIR, temp_model_rel)
    output_csv = os.path.join(BASE_DIR, output_csv_rel)

    # Prepare model with injected experiment
    shutil.copy2(MODEL_NAME, temp_model_path)
    with open(temp_model_path, "r", encoding="utf-8") as f:
        content = f.read()
    sections = content.split("@#$#@#$#@\n")
    if len(sections) > 7:
        sections[7] = create_behavior_space_xml(name, config)
    with open(temp_model_path, "w", encoding="utf-8") as f:
        f.write("@#$#@#$#@\n".join(sections))

    command = [
        NETLOGO_HEADLESS, "--headless",
        "--model", temp_model_rel,
        "--experiment", name,
        "--table", output_csv_rel
    ]

    result = subprocess.run(command, capture_output=True, text=True,
                            cwd=BASE_DIR)

    if result.returncode != 0:
        print(f"  [ERRORE] {name}:")
        print(result.stderr[-500:] if len(result.stderr) > 500 else result.stderr)
        return None

    print(f"  [OK] Risultati salvati in {output_csv_rel}")

    # Parse results
    df = pd.read_csv(output_csv, skiprows=6)
    metric_cols = [c for c in df.columns if c not in
                   ["[run number]", "[step]"] and not any(
                       p in c for p in config["params"].keys())]
    for col in metric_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    return df


def main():
    all_results = {}

    for name, config in EXPERIMENTS.items():
        df = run_single_experiment(name, config)
        if df is not None:
            all_results[name] = df

    # Print aggregate comparison table
    print("\n" + "=" * 70)
    print("TABELLA COMPARATIVA — Social Types (200 pedoni, R=10, 1000 step)")
    print("=" * 70)

    rows = []
    for name, df in all_results.items():
        label = name.replace("Exp5a_", "").replace("Exp5b_", "").replace(
            "Exp5c_", "").replace("Exp5d_", "")
        row = {
            "Profilo": label,
            "Throughput Totale": df["throughput-total"].mean(),
            "Mean Exit Time": df["mean-exit-time"].mean(),
            "Effective Speed": df["mean [effective-speed] of turtles"].mean(),
            "Phi Max": df["phi-max"].mean(),
        }
        rows.append(row)

    summary = pd.DataFrame(rows)
    print(summary.to_string(index=False))

    # Save summary CSV
    summary_path = os.path.join(RESULTS_DIR, "Exp5_SocialTypes_summary.csv")
    summary.to_csv(summary_path, index=False)
    print(f"\nSummary salvato in: {summary_path}")


if __name__ == "__main__":
    main()
