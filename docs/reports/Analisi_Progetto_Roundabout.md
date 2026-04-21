# Analisi del Progetto "DAI Roundabout" — Passive DAI & Floor Field Model

Questo documento analizza il modello NetLogo `DAI_roundabout.nlogo`, interpretandolo come un sistema di coordinamento intelligente mediato dall'ambiente.

## 1. Cosa succede nel modello?

Il progetto implementa un **Advanced Floor Field Model (FFM)** per simulare la dinamica pedonale in una rotonda a quattro bracci. A differenza di un semplice corridoio, qui la sfida è la gestione di flussi ortogonali incrociati.

### Meccaniche principali:
*   **Geometria come Algoritmo:** La rotonda non è solo un contenitore, ma un dispositivo di **DAI Passiva**. L'isola centrale rompe la simmetria dell'intersezione, trasformando "crossing flows" potenzialmente conflittuali in "tangential flows" ordinati.
*   **Static Floor Field Polarizzato (Penalty Trick):** Il campo statico $S$ non mappa solo la distanza minima. Grazie a un bias artificiale nel calcolo BFS, il gradiente "spinge" i pedoni a ruotare in senso antiorario, codificando una norma sociale direttamente nella topologia del campo.
*   **Campi Dinamico (D) e Repulsivo (R):**
    *   **D:** Media la stigmergia tra agenti dello stesso gruppo (tracce di percorso).
    *   **R:** Modella il costo sociale della prossimità, riducendo la probabilità di occupare celle vicino ad altri pedoni.
*   **Transizione di Fase:** Il modello utilizza il vicinato di Moore (8 direzioni) per consentire micro-deviazioni diagonali, migliorando la fluidità rispetto a un movimento puramente cardinale.

---

## 2. Quali riflessioni e metriche vengono misurate?

Il valore aggiunto del progetto risiede nella validazione scientifica tramite 72 test automatizzati.

### Metriche Chiave:
*   **Vorticità Spontanea ($\phi$):** Misura il grado di segregazione dei flussi. A differenza di un corridoio, nella rotonda $\phi$ raggiunge il massimo quasi istantaneamente, dimostrando che l'ordine è "geometry-driven" (guidato dalla forma) prima ancora che sociale.
*   **Capacità e Saturazione (Diagramma Fondamentale):** Analisi della relazione tra densità di popolazione e tempi medi di uscita. Viene identificata una soglia critica oltre la quale il sistema passa da regime laminare a congestionato.
*   **Ottimizzazione Urbanistica (Raggio dell'Isola):** Studio dell'impatto del raggio centrale. Lo script evidenzia un **effetto clogging non monotono**: un'isola troppo grande restringe la sezione utile e allunga i percorsi, peggiorando le performance globali.
*   **Resilienza allo stress repulsivo:** Verifica di come il sistema reagisca a valori elevati di $Kr$, confermando che la geometria mitiga i blocchi frontali anche in condizioni di alta "paura del contatto".

---

## 3. Commenti Critici e Insight

### Punti di Forza:
1.  **Stigmergia Ambientale:** Il modello dimostra brillantemente come l'intelligenza di sistema possa essere "scaricata" sulla geometria, riducendo il carico cognitivo richiesto agli agenti.
2.  **Solidità Letteraria:** Integra concetti da diversi paper (Burstedde, Weng, Yanagisawa), offrendo una visione d'insieme su come la topologia urbana influenzi l'auto-organizzazione.
3.  **Approccio Data-Driven:** L'uso di BehaviorSpace e la post-elaborazione ne fanno un modello pronto per la ricerca DAI applicata.

### Insight per la Relazione:
*   **Il paradosso dell'ostacolo:** L'isola centrale è utile per eliminare il conflitto frontale, ma diventa un limite fisico se non dimensionata correttamente rispetto alla larghezza delle corsie.
*   **Limiti del CA:** Essendo un modello ad automi cellulari, la velocità è quantizzata. Rispetto ai *Social Force Models* continui, eccelle nello studio della competizione spaziale discreta ma perde fedeltà nelle accelerazioni fluide.

---
*Analisi generata per il corso di Distributed Artificial Intelligence — Revisione del Modello Roundabout.*
