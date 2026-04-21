import subprocess
import pandas as pd
import os
import shutil
import xml.etree.ElementTree as ET
from concurrent.futures import ProcessPoolExecutor, as_completed

# Configurazione
NETLOGO_HEADLESS = r"C:\Program Files\NetLogo 7.0.3\NetLogo_Console.exe"
# BASE_DIR è la radice del progetto (una cartella sopra questa)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_NAME = os.path.join(BASE_DIR, "models", "DAI_roundabout.nlogo")
TEMP_DIR = os.path.join(BASE_DIR, "results", "temp")
RESULTS_DIR = os.path.join(BASE_DIR, "results", "datasets")

experiments = {
    "Exp1_FundamentalDiagram": {
        "params": {
            "num-pedestrians": [40, 80, 120, 160, 200, 240, 280, 320, 360, 400],
            "Kd": [2.0],
            "Ks": [1.0],
            "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5,  # 5 reps for statistical robustness (was 3)
        "steps": 500,
        # effective-speed = move-count/ticks (true speed); mean-exit-time = journey duration
        "metrics": ["throughput-per-tick", "mean [effective-speed] of turtles", "mean-exit-time"]
    },
    "Exp2_SelfOrganization": {
        "params": {
            "num-pedestrians": [160],
            "Kd": [0.0, 0.5, 1.0, 2.0, 4.0, 8.0],
            "Ks": [1.0],
            "Kr": [1.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5,
        "steps": 1000,
        # phi-stabilization-tick captures RATE of order emergence (more sensitive than phi-max)
        "metrics": ["phi-max", "phi-stabilization-tick"]
    },
    "Exp3_GeometryOptimization": {
        "params": {
            "num-pedestrians": [240],
            "Kd": [2.0],
            "Ks": [1.0],
            "Kr": [1.0],
            "roundabout-radius": [5, 8, 10, 12]  # removed 15: R_outer=23 > world half=20 → broken geometry
        },
        "repetitions": 5,
        "steps": 1000,
        "metrics": ["throughput-total", "mean-exit-time"]
    },
    "Exp4_RepulsionImpact": {
        "params": {
            "num-pedestrians": [160],
            "Kd": [2.0],
            "Ks": [1.0],
            "Kr": [0.5, 1.0, 2.0, 5.0],
            "roundabout-radius": [10]
        },
        "repetitions": 5,
        "steps": 1000,
        # effective-speed replaces speed (was always 1.0 — never updated in agent vars)
        "metrics": ["mean [effective-speed] of turtles", "mean-exit-time", "throughput-per-tick"]
    }
}

def create_behavior_space_xml(name, config):
    xml = ET.Element("experiments")
    exp = ET.SubElement(xml, "experiment", name=name, repetitions=str(config["repetitions"]), runMetricsEveryStep="false")
    ET.SubElement(exp, "setup").text = "setup"
    ET.SubElement(exp, "go").text = "go"
    ET.SubElement(exp, "timeLimit", steps=str(config["steps"]))
    
    for metric in config["metrics"]:
        ET.SubElement(exp, "metric").text = metric
        
    for var, values in config["params"].items():
        val_set = ET.SubElement(exp, "enumeratedValueSet", variable=var)
        for v in values:
            ET.SubElement(val_set, "value", value=str(v))
            
    return ET.tostring(xml, encoding="unicode") + "\n"

def run_experiment(name, config):
    print(f"\n>>> Avvio esperimento: {name}...")
    
    if not os.path.exists(TEMP_DIR):
        os.makedirs(TEMP_DIR)
        
    # Usa percorsi relativi per evitare problemi con caratteri speciali nei percorsi assoluti
    # I percorsi devono essere relativi alla CWD (che assumiamo sia la radice del progetto)
    temp_model_rel = os.path.join("results", "temp", f"{name}.nlogo")
    output_csv_rel = os.path.join("results", "datasets", f"{name}_results.csv")
    
    temp_model_path = os.path.join(BASE_DIR, temp_model_rel)
    output_csv = os.path.join(BASE_DIR, output_csv_rel)
    
    # Prepara il modello con l'esperimento iniettato
    shutil.copy2(MODEL_NAME, temp_model_path)
    with open(temp_model_path, "r", encoding="utf-8") as f:
        content = f.read()
    sections = content.split("@#$#@#$#@\n")
    if len(sections) > 7:
        sections[7] = create_behavior_space_xml(name, config)
    with open(temp_model_path, "w", encoding="utf-8") as f:
        f.write("@#$#@#$#@\n".join(sections))
        
    command = [
        NETLOGO_HEADLESS,
        "--headless",
        "--model", temp_model_rel,
        "--experiment", name,
        "--table", output_csv_rel
    ]
    
    print(f"Esecuzione in corso...")
    result = subprocess.run(command, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Errore in {name}:")
        print(result.stderr)
        return False
        
    print(f"Esperimento {name} completato. Risultati salvati in {output_csv}")
    return True

if __name__ == "__main__":
    if not os.path.exists(RESULTS_DIR):
        os.makedirs(RESULTS_DIR)
    if not os.path.exists(TEMP_DIR):
        os.makedirs(TEMP_DIR)

    print(f"Avvio {len(experiments)} esperimenti in parallelo (max 4 worker)...")
    results_status = {}
    with ProcessPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(run_experiment, name, config): name
                   for name, config in experiments.items()}
        for future in as_completed(futures):
            name = futures[future]
            ok = future.result()
            results_status[name] = "OK" if ok else "ERRORE"
            print(f"  [{results_status[name]}] {name}")

    print("\n=== RIEPILOGO ===")
    for name, status in results_status.items():
        print(f"  {status}: {name}")
    print("=== COMPLETATO ===")
