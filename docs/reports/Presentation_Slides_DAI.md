# Presentation Slides: Pedestrian Dynamics in a Roundabout
## A Study in Passive Distributed Artificial Intelligence

### Slide 1: Title Slide
**Title:** Pedestrian Dynamics in a Roundabout: A Passive Distributed Artificial Intelligence System
**Subtitle:** Modeling Dynamical Crowd Coordination through Cellular Automata and Floor Fields
**Author:** [Your Name / Group Name]
**Course:** Distributed Artificial Intelligence
**Objective:** To analyze how environmental geometry can act as a "passive intelligence" to coordinate autonomous agents.

---

### Slide 2: Introduction & Concept
**The Roundabout as Passive DAI**
- **Passive Coordination:** Coordination emerges from spatial constraints rather than explicit communication or negotiation.
- **Stigmergy:** The environment stores operational information via fields and obstacles.
- **Hypothesis:** Circular geometry converts conflicting crossing flows into laminar tangential flows, imposing spontaneous rotational order.
- **Key Reference:** Weng et al. (2006) – Roundabouts vs. Traditional Cross Intersections.

---

### Slide 3: Theoretical Framework
**The Floor Field Model (FFM)**
- Based on the foundational work by **Burstedde et al. (2001)**.
- **Cellular Automata (CA):** Discrete space (Moore Neighborhood) and discrete time.
- **The Equation:** 
  $$P_{ij} \propto (1 - n_{ij}) \cdot \exp(K_s S_{ij}) \cdot \exp(K_d D_{ij}) \cdot \exp(-K_r R_{ij})$$
- **Components:**
  - $S$ (Static Field): Topology-based distance to target.
  - $D$ (Dynamic Field): Stigmergic trails (trail following).
  - $R$ (Repulsive Field): Socio-spatial cost of proximity.

---

### Slide 4: Model Architecture
**Geometric Design & Agent Logic**
- **Environment:** 41x41 grid with four arms (East, West, North, South).
- **The Central Island:** A physical obstacle that breaks symmetry.
- **Agent Behavior:**
  - 8-neighbor Moore movement + "Stay" option.
  - Stochastic transition based on field intensities.
  - Volume exclusion (one agent per patch).
- **Implementation:** Built in NetLogo (`DAI_roundabout.nlogo`).

---

### Slide 5: The "Penalty Trick"
**Inducing Global Order through Local Fields**
- **BFS Multi-source:** Static fields ($S_0...S_3$) generated via Breadth-First Search.
- **Directional Bias:** During BFS propagation, path costs are increased for "forbidden" turns (e.g., clockwise shortcuts).
- **Passive Intelligence:** The agent "sees" a higher cost for going the wrong way, inducing a global counter-clockwise rotation without explicit "rules" like "always turn left".
- **Result:** Structural self-organization assisted by geometry.

---

### Slide 6: Experimental Setup
**Performance Evaluation Metrics**
- **Total Throughput:** Total number of agents reaching their destination.
- **Mean Exit Time:** Average ticks required for an agent to traverse the system.
- **Vorticity/Segregation ($\phi$):** Measuring the emergence of circular lanes.
- **Parameters Scanned (72 Tests):**
  - Population Density (40 to 400 pedestrians).
  - Stigmergic Intensity ($K_d$).
  - Island Radius ($R$).
  - Repulsive Sensitivity ($K_r$).

---

### Slide 7: Results - Fundamental Diagram (Exp 1)
**Density vs. Efficiency**
- **Phase Transition:** A clear shift from laminar flow to congestion.
- **Key Data:**
  | Pedestrians | Density (ped/patch) | Mean Exit Time (ticks) |
  | :--- | :---: | :---: |
  | 40 | 0.065 | 150.16 |
  | 200 | 0.325 | 175.53 |
  | 400 | 0.649 | 217.84 |
- **Insight:** As density increases, social friction (repulsion) and volume exclusion dominate, slowing down the system breakthrough.

---

### Slide 8: Results - Self-Organization & Vorticity (Exp 2)
**Spontaneous Order Alignment**
- **Immediate Segregation:** Unlike linear corridors where lanes form slowly, the roundabout imposes order immediately ($\phi \approx 1.0$ from $t=0$).
- **Geometric Calibration:** The dynamic field ($K_d$) refines the flow but the geometry is the primary driver.
- **Helbing's Theory (2005):** Self-organization isn't just about agent-agent interaction; here, the environment is a "structural catalyst" for order.

---

### Slide 9: Results - Geometric Optimization (Exp 3)
**The Clogging Effect of the Central Island**
- **Hypothesis:** A larger island might separate flows better.
- **Reality:** Larger islands reduce effective lane width and increase path length.
- **Data (at 240 Peds):**
  | Radius | Total Throughput | Mean Exit Time |
  | :--- | :---: | :---: |
  | 5 | **1052.6** | **199.53** |
  | 12 | 888.2 | 230.36 |
- **Conclusion:** There is a "Critical Radius": the island must be large enough to block direct crossing but small enough to avoid becoming a dissipative obstacle (Yanagisawa et al., 2019).

---

### Slide 10: Conclusion & Future Outlook
**Summary of Findings**
- **Success:** The roundabout effectively converts 90° conflicts into tangential interactions, delaying the collapse of throughput compared to traditional intersections.
- **Passive Intelligence:** Architecture can "pre-process" conflicts, reducing the cognitive load required from agents.
- **Future Work:**
  - Transition from Discrete (CA) to Continuous (Social Force) models.
  - Heterogeneous populations (varying speeds/aggressiveness).
  - Adaptive signal control (hybrid Active/Passive DAI).

**References:** Burstedde (2001), Helbing (2005), Zhang (2012), Weng (2006).
