import subprocess
import pandas as pd
import os
import shutil

# Configurazione
NETLOGO_HEADLESS = r"C:\Program Files\NetLogo 7.0.3\NetLogo_Console.exe"
# BASE_DIR è la radice del progetto
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_NAME = os.path.join(BASE_DIR, "models", "DAI_roundabout.nlogo")
TEMP_DIR = r"C:\temp_netlogo" # Mantiene C:\ per bypassare bug Unicode se necessario
OUTPUT_CSV = os.path.join(BASE_DIR, "results", "datasets", "test_results.csv")
XML_NAME = os.path.join(BASE_DIR, "models", "experiment.xml")

def create_experiment_xml():
    xml_content = """<experiments>
  <experiment name="Automated_Test" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>phi-max</metric>
    <enumeratedValueSet variable="num-pedestrians">
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Kd">
      <value value="0.0"/>
      <value value="2.0"/>
      <value value="4.0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ks">
      <value value="1.0"/>
      <value value="2.0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
"""
    return xml_content

def run_simulation():
    if not os.path.exists(TEMP_DIR):
        os.makedirs(TEMP_DIR)
        
    temp_model_path = os.path.join(TEMP_DIR, os.path.basename(MODEL_NAME))
    temp_output_csv = os.path.join(TEMP_DIR, os.path.basename(OUTPUT_CSV))
    
    # Copia il modello
    shutil.copy2(MODEL_NAME, temp_model_path)
    
    # Inietta nativamente l'esperimento XML
    with open(temp_model_path, "r", encoding="utf-8") as f:
        content = f.read()
    sections = content.split("@#$#@#$#@\n")
    if len(sections) > 7:
        sections[7] = create_experiment_xml()
    with open(temp_model_path, "w", encoding="utf-8") as f:
        f.write("@#$#@#$#@\n".join(sections))
    
    command = [
        NETLOGO_HEADLESS,
        "--headless",
        "--model", temp_model_path,
        "--experiment", "Automated_Test",
        "--table", temp_output_csv
    ]
    print(f"Esecuzione in corso in directory ASCII per byapassare bug Unicode Java...")
    result = subprocess.run(command, capture_output=True, text=True, cwd=TEMP_DIR)
    
    if result.returncode != 0:
        print("Errore durante l'esecuzione di NetLogo:")
        print(result.stderr)
        print(result.stdout)
        return False
        
    # Copia i risultati indietro
    if os.path.exists(temp_output_csv):
        shutil.copy2(temp_output_csv, OUTPUT_CSV)
    
    # Cleanup
    shutil.rmtree(TEMP_DIR, ignore_errors=True)
    
    print("Simulazione completata con successo.")
    return True

def analyze_results():
    if not os.path.exists(OUTPUT_CSV):
        print("File CSV non trovato.")
        return
    
    # NetLogo headless CSV output has 6 lines of headers before data
    df = pd.read_csv(OUTPUT_CSV, skiprows=6)
    print("\\n--- ANALYSIS RESULTS ---")
    print(df[['[run number]', 'num-pedestrians', 'Kd', 'Ks', 'phi-max']])
    print("-------------------------")

if __name__ == "__main__":
    if run_simulation():
        analyze_results()
