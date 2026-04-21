import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Configurazione percorsi
# BASE_DIR è la radice del progetto (una cartella sopra questa)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS_DIR = os.path.join(BASE_DIR, "results", "datasets")
PLOTS_DIR = os.path.join(BASE_DIR, "results", "plots")
if not os.path.exists(PLOTS_DIR):
    os.makedirs(PLOTS_DIR)

sns.set_theme(style="whitegrid")

def load_netlogo_csv(filename):
    # Salta le prime 6 righe di intestazione di NetLogo
    df = pd.read_csv(os.path.join(RESULTS_DIR, filename), skiprows=6)
    return df

WALKABLE_PATCHES = 40 * 40 - 984  # approx wall count for default geometry (radius=10, lw=8, chw=6)

def analyze_exp1():
    print("Analisi Esp1: Fundamental Diagram...")
    df = load_netlogo_csv("Exp1_FundamentalDiagram_results.csv")

    # Normalized density (pedestrians per walkable patch) for literature comparison
    df['density'] = df['num-pedestrians'] / WALKABLE_PATCHES

    speed_col = "mean [effective-speed] of turtles"
    summary = df.groupby("num-pedestrians").agg({
        "throughput-per-tick": ["mean", "std"],
        speed_col: ["mean", "std"],
        "mean-exit-time": ["mean", "std"],
        "density": "mean"
    }).reset_index()
    summary.columns = ['num-pedestrians', 'flow_mean', 'flow_std',
                        'speed_mean', 'speed_std', 'exit_time_mean', 'exit_time_std', 'density']

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    # Flow vs density
    axes[0].errorbar(summary['density'], summary['flow_mean'], yerr=summary['flow_std'],
                     marker='o', color='tab:red', capsize=4)
    axes[0].set_xlabel('Densità (ped/patch)')
    axes[0].set_ylabel('Throughput (ped/tick)')
    axes[0].set_title('Diagramma Fondamentale')

    # Effective speed vs density
    axes[1].errorbar(summary['density'], summary['speed_mean'], yerr=summary['speed_std'],
                     marker='s', linestyle='--', color='tab:blue', capsize=4)
    axes[1].set_xlabel('Densità (ped/patch)')
    axes[1].set_ylabel('Velocità Effettiva (move/tick)')
    axes[1].set_title('Velocità Effettiva vs Densità')

    # Mean exit time vs density
    axes[2].errorbar(summary['density'], summary['exit_time_mean'], yerr=summary['exit_time_std'],
                     marker='^', linestyle=':', color='tab:green', capsize=4)
    axes[2].set_xlabel('Densità (ped/patch)')
    axes[2].set_ylabel('Tempo Medio di Uscita (tick)')
    axes[2].set_title('Tempo di Viaggio vs Densità')

    fig.suptitle('Exp1: Diagramma Fondamentale')
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp1_Fundamental_Diagram.png"), dpi=150)
    plt.close()

def analyze_exp2():
    print("Analisi Esp2: Self-Organization (Lane Formation)...")
    df = load_netlogo_csv("Exp2_SelfOrganization_results.csv")

    # phi-max is always 1.0 (geometry dominates) — use stabilization tick as sensitive metric
    summary = df.groupby("Kd").agg({
        "phi-max": ["mean", "std"],
        "phi-stabilization-tick": ["mean", "std"]
    }).reset_index()
    summary.columns = ['Kd', 'phi_mean', 'phi_std', 'stab_mean', 'stab_std']

    # Replace -1 (never stabilized) with max steps for plotting
    max_steps = 1000
    summary['stab_mean'] = summary['stab_mean'].replace(-1, max_steps)

    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    axes[0].errorbar(summary['Kd'], summary['phi_mean'], yerr=summary['phi_std'],
                     marker='o', color='tab:purple', capsize=4)
    axes[0].set_xlabel('Kd (peso campo dinamico)')
    axes[0].set_ylabel('Phi Max (segregazione)')
    axes[0].set_title('Phi Max vs Kd')
    axes[0].set_ylim(0, 1.1)

    # Stabilization tick: lower = order emerges faster
    axes[1].errorbar(summary['Kd'], summary['stab_mean'], yerr=summary['stab_std'],
                     marker='s', linestyle='--', color='tab:orange', capsize=4)
    axes[1].set_xlabel('Kd (peso campo dinamico)')
    axes[1].set_ylabel('Tick di Stabilizzazione (phi≥0.9)')
    axes[1].set_title('Velocità di Auto-Organizzazione vs Kd\n(basso = ordine emerge prima)')

    fig.suptitle('Exp2: Self-Organization e Lane Formation')
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp2_Lane_Formation.png"), dpi=150)
    plt.close()

def analyze_exp3():
    print("Analisi Esp3: Geometry Optimization...")
    df = load_netlogo_csv("Exp3_GeometryOptimization_results.csv")

    summary = df.groupby("roundabout-radius").agg({
        "throughput-total": ["mean", "std"],
        "mean-exit-time": ["mean", "std"]
    }).reset_index()
    summary.columns = ['radius', 'tp_mean', 'tp_std', 'et_mean', 'et_std']

    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    axes[0].errorbar(summary['radius'], summary['tp_mean'], yerr=summary['tp_std'],
                     marker='o', color='tab:blue', capsize=4)
    axes[0].set_xlabel('Raggio Rotonda')
    axes[0].set_ylabel('Throughput Totale (1000 tick)')
    axes[0].set_title('Throughput vs Raggio')

    axes[1].errorbar(summary['radius'], summary['et_mean'], yerr=summary['et_std'],
                     marker='s', linestyle='--', color='tab:red', capsize=4)
    axes[1].set_xlabel('Raggio Rotonda')
    axes[1].set_ylabel('Tempo Medio Uscita (tick)')
    axes[1].set_title('Tempo di Viaggio vs Raggio\n(alto = percorso più lungo)')

    fig.suptitle('Exp3: Ottimizzazione Geometrica')
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp3_Geometry_Optimization.png"), dpi=150)
    plt.close()

def analyze_exp4():
    print("Analisi Esp4: Repulsion Impact...")
    df = load_netlogo_csv("Exp4_RepulsionImpact_results.csv")

    speed_col = "mean [effective-speed] of turtles"
    summary = df.groupby("Kr").agg({
        speed_col: ["mean", "std"],
        "mean-exit-time": ["mean", "std"],
        "throughput-per-tick": ["mean", "std"]
    }).reset_index()
    summary.columns = ['Kr', 'speed_mean', 'speed_std',
                        'et_mean', 'et_std', 'tp_mean', 'tp_std']

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    axes[0].errorbar(summary['Kr'], summary['speed_mean'], yerr=summary['speed_std'],
                     marker='D', color='tab:green', capsize=4)
    axes[0].set_xlabel('Kr (peso repulsione)')
    axes[0].set_ylabel('Velocità Effettiva (move/tick)')
    axes[0].set_title('Velocità Effettiva vs Kr')

    axes[1].errorbar(summary['Kr'], summary['et_mean'], yerr=summary['et_std'],
                     marker='o', linestyle='--', color='tab:red', capsize=4)
    axes[1].set_xlabel('Kr (peso repulsione)')
    axes[1].set_ylabel('Tempo Medio Uscita (tick)')
    axes[1].set_title('Tempo di Viaggio vs Kr')

    axes[2].errorbar(summary['Kr'], summary['tp_mean'], yerr=summary['tp_std'],
                     marker='s', linestyle=':', color='tab:blue', capsize=4)
    axes[2].set_xlabel('Kr (peso repulsione)')
    axes[2].set_ylabel('Throughput (ped/tick)')
    axes[2].set_title('Flusso vs Kr')

    fig.suptitle('Exp4: Impatto della Repulsione')
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp4_Repulsion_Impact.png"), dpi=150)
    plt.close()

def analyze_exp5():
    print("Analisi Esp5: Social Types...")

    # --- Load individual sub-experiment files (Exp5a-d) ---
    files = {
        "Baseline":   "Exp5a_Baseline_results.csv",
        "Aggressive":  "Exp5b_Aggressive_results.csv",
        "Prudent":     "Exp5c_Prudent_results.csv",
        "Imitator":    "Exp5d_Imitator_results.csv",
    }
    profiles = []
    for profile, fname in files.items():
        df = load_netlogo_csv(fname)
        df['profile'] = profile
        profiles.append(df)
    all_runs = pd.concat(profiles, ignore_index=True)

    speed_col = "mean [effective-speed] of turtles"

    # Compute per-profile statistics
    summary = all_runs.groupby("profile").agg({
        "throughput-total": ["mean", "std"],
        "mean-exit-time": ["mean", "std"],
        speed_col: ["mean", "std"],
    })
    summary.columns = ['tp_mean', 'tp_std', 'et_mean', 'et_std', 'speed_mean', 'speed_std']
    # Ensure ordering
    order = ["Baseline", "Aggressive", "Prudent", "Imitator"]
    summary = summary.reindex(order)

    # ================================================================
    #  PLOT 1 — Grouped bar chart (summary comparison)
    # ================================================================
    fig, axes = plt.subplots(1, 3, figsize=(16, 5))
    colors = ['#4C72B0', '#DD8452', '#55A868', '#C44E52']
    x = range(len(order))

    # Throughput Totale
    axes[0].bar(x, summary['tp_mean'], yerr=summary['tp_std'],
                color=colors, capsize=5, edgecolor='white', linewidth=0.8)
    axes[0].set_xticks(x)
    axes[0].set_xticklabels(order, rotation=15, ha='right')
    axes[0].set_ylabel('Throughput Totale (1000 tick)')
    axes[0].set_title('Throughput per Profilo')
    for i, v in enumerate(summary['tp_mean']):
        axes[0].text(i, v + summary['tp_std'].iloc[i] + 0.5, f'{v:.1f}',
                     ha='center', va='bottom', fontsize=9, fontweight='bold')

    # Mean Exit Time
    axes[1].bar(x, summary['et_mean'], yerr=summary['et_std'],
                color=colors, capsize=5, edgecolor='white', linewidth=0.8)
    axes[1].set_xticks(x)
    axes[1].set_xticklabels(order, rotation=15, ha='right')
    axes[1].set_ylabel('Tempo Medio di Uscita (tick)')
    axes[1].set_title('Tempo di Uscita per Profilo')
    for i, v in enumerate(summary['et_mean']):
        axes[1].text(i, v + summary['et_std'].iloc[i] + 0.5, f'{v:.1f}',
                     ha='center', va='bottom', fontsize=9, fontweight='bold')

    # Effective Speed
    axes[2].bar(x, summary['speed_mean'], yerr=summary['speed_std'],
                color=colors, capsize=5, edgecolor='white', linewidth=0.8)
    axes[2].set_xticks(x)
    axes[2].set_xticklabels(order, rotation=15, ha='right')
    axes[2].set_ylabel('Velocità Effettiva Media (move/tick)')
    axes[2].set_title('Velocità Effettiva per Profilo')
    for i, v in enumerate(summary['speed_mean']):
        axes[2].text(i, v + summary['speed_std'].iloc[i] + 0.001, f'{v:.4f}',
                     ha='center', va='bottom', fontsize=9, fontweight='bold')

    fig.suptitle('Exp5: Impatto dei Tipi Sociali — Confronto Profili', fontsize=14)
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp5_Social_Types_Comparison.png"), dpi=150)
    plt.close()

    # ================================================================
    #  PLOT 2 — Per-run scatter + mean with error bars (detail view)
    # ================================================================
    fig, axes = plt.subplots(1, 3, figsize=(16, 5))
    metrics = [
        ('throughput-total', 'Throughput Totale', 'Throughput Totale (1000 tick)'),
        ('mean-exit-time', 'Tempo Medio di Uscita', 'Tempo Medio di Uscita (tick)'),
        (speed_col, 'Velocità Effettiva', 'Velocità Effettiva (move/tick)'),
    ]
    markers = ['o', 's', 'D', '^']

    for ax, (col, title, ylabel) in zip(axes, metrics):
        for idx, profile in enumerate(order):
            data = all_runs[all_runs['profile'] == profile][col]
            # Jittered x positions for visibility
            jitter = (idx - 1.5) * 0.15
            xs = [idx + jitter * 0.01 + j * 0.0 for j in range(len(data))]
            ax.scatter([idx] * len(data), data, color=colors[idx],
                       marker=markers[idx], alpha=0.6, s=50, zorder=3,
                       label=profile if ax == axes[0] else None)
            # Mean + error bar
            mean_val = data.mean()
            std_val = data.std()
            ax.errorbar(idx, mean_val, yerr=std_val, fmt='_', color='black',
                        markersize=15, capsize=8, capthick=2, linewidth=2, zorder=4)

        ax.set_xticks(range(len(order)))
        ax.set_xticklabels(order, rotation=15, ha='right')
        ax.set_ylabel(ylabel)
        ax.set_title(title)

    axes[0].legend(loc='best', framealpha=0.9)
    fig.suptitle('Exp5: Tipi Sociali — Distribuzione per Run', fontsize=14)
    fig.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, "Exp5_Social_Types_Distribution.png"), dpi=150)
    plt.close()


if __name__ == "__main__":
    analyze_exp1()
    analyze_exp2()
    analyze_exp3()
    analyze_exp4()
    analyze_exp5()
    print(f"\nAnalisi completata. I grafici sono stati salvati in: {PLOTS_DIR}")
