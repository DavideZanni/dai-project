# Progetto Distributed Artificial Intelligence - Pedestrian Dynamics

Questo progetto implementa una simulazione di dinamiche pedonali in una rotonda utilizzando NetLogo e Python per l'analisi e l'esecuzione degli esperimenti.

## Struttura del Progetto

- **`models/`**: Contiene i modelli NetLogo (`.nlogo`) e le configurazioni degli esperimenti (`.xml`).
- **`src/`**: Script Python per l'automazione, l'esecuzione parallela degli esperimenti e l'analisi dei dati.
- **`docs/`**: Documentazione di progetto, relazioni scientifiche e note di lavoro.
- **`results/`**: Output dei test, file CSV con i risultati degli esperimenti e grafici generati.
- **`archive/`**: Versioni precedenti o materiali di supporto dei collaboratori.

## Come eseguire gli esperimenti

Gli script sono stati configurati per essere eseguiti dalla radice del progetto:

1. Per eseguire una batteria di test completa in parallelo:
   ```bash
   python src/run_all_experiments.py
   ```
2. Per analizzare i dati e generare i grafici:
   ```bash
   python src/analyze_results.py
   ```
