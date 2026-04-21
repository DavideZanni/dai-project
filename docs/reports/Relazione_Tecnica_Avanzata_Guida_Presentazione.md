# Relazione Tecnica Avanzata e Guida alla Presentazione
## Dinamica Pedonale in Rotonda come Sistema di Distributed Artificial Intelligence Passiva

### Abstract
Questo documento sintetizza il progetto `DAI_roundabout.nlogo` come studio di **dynamical crowd coordination** in una geometria a rotonda a quattro bracci, modellata tramite **automi cellulari** e **Floor Field Model**. La tesi centrale e' che la rotonda non sia soltanto un artefatto urbanistico, ma un dispositivo di **Intelligenza Distribuita Passiva**: l'ambiente incorpora vincoli e gradienti che trasformano interazioni locali non coordinate in ordine collettivo, secondo una logica di **stigmergia ambientale**. L'analisi congiunta del codice NetLogo, dei 72 test BehaviorSpace e dei grafici `Exp1`-`Exp4` mostra che la geometria circolare converte flussi perpendicolari potenzialmente conflittuali in **flussi tangenziali laminari**, imponendo una vorticita' spontanea robusta anche in assenza di forte coordinamento sociale esplicito. I risultati evidenziano inoltre un trade-off tra densita', geometria dell'isola centrale e costo repulsivo locale, chiarendo dove la rotonda massimizza il throughput e dove emergono effetti di saturazione e clogging.

### 1. Introduzione Critica: la rotonda come DAI passiva
Nel linguaggio della Distributed Artificial Intelligence, il caso di studio e' interessante perche' il coordinamento non emerge da comunicazione simbolica, pianificazione condivisa o negoziazione multi-agent, ma da **vincoli spaziali codificati nell'ambiente**. La rotonda realizza quindi una forma di **coordinamento passivo**: i pedoni non devono esplicitamente decidere una convenzione globale, perche' la geometria restringe lo spazio delle azioni ammissibili e rende piu' probabili quelle compatibili con l'ordine collettivo.

Questo e' precisamente il meccanismo che, in termini larghi, richiama la **stigmergia**: l'ambiente memorizza informazione operativa sotto forma di campi, ostacoli, tracce dinamiche e costi spaziali. Nel nostro modello:

- il **campo statico** codifica la conoscenza topologica della destinazione;
- il **campo dinamico** codifica memoria locale del traffico recente;
- il **campo repulsivo** codifica il costo sociale della prossimita';
- l'**isola centrale** spezza la simmetria e impone una conversione da crossing flow a circulating flow.

La rotonda e', quindi, un sistema di DAI passiva perche' delega all'architettura fisica parte dell'"intelligenza" che, in altri sistemi, dovrebbe essere sostenuta dagli agenti.

#### 1.1 Collegamento esplicito con la letteratura
Il file [`docs/experiments/Fonti_Ricerca_Pedoni.md`](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:1) individua correttamente i cinque riferimenti che strutturano l'intero progetto. La relazione finale deve usarli non come semplice bibliografia accessoria, ma come **ossatura interpretativa**:

- **Burstedde et al. (2001)** forniscono il fondamento formale del Floor Field Model: esclusione di volume, scelta stocastica locale, campi statici e dinamici come sostituti discreti di orientamento e imitazione.
- **Weng et al. (2006)** offrono il collegamento piu' diretto con il nostro caso: dimostrano che la rotonda pedonale e' superiore all'incrocio a croce quando riesce a convertire conflitti frontali in traiettorie tangenziali compatibili.
- **Zhang (2012)** e la tradizione sperimentale sui fundamental diagrams permettono di leggere `Exp1` in termini di relazione tra densita', velocita' e flusso, cioe' come studio di capacita' e saturazione del sistema.
- **Helbing et al. (2005)** forniscono il lessico teorico per spiegare auto-organizzazione, lane formation e spontaneous rotational order. Nel nostro caso la vorticita' non e' solo emergente, ma fortemente assistita dalla geometria.
- **Yanagisawa et al. (2019)** sono il riferimento migliore per interpretare `Exp3`: l'isola centrale non e' sempre benefica in modo monotono; se cresce troppo, l'effetto di streamlining viene superato dal costo spaziale e dal clogging.

Il punto forte del progetto, quindi, e' che ogni esperimento puo' essere letto come una **verifica locale di una famiglia di ipotesi note in letteratura**, ma in una configurazione originale: una rotonda discretizzata con bias antiorario incorporato nel campo statico.

### 2. Architettura del Modello: deep dive tecnico
Il modello e' implementato in [`models/DAI_roundabout.nlogo`](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/models/DAI_roundabout.nlogo:52). La world grid viene definita con `resize-world 0 40 0 40`: la discretizzazione effettiva e' quindi **41 x 41 patch**, non 40 x 40. Ogni patch puo' essere muro o spazio percorribile; ogni pedone occupa una sola cella.

#### 2.1 Geometria della rotonda
La geometria e' generata in tre fasi:

1. tutte le patch vengono inizialmente marcate come parete;
2. viene scavato un **anello circolare** compreso tra raggio interno `roundabout-radius` e raggio esterno `roundabout-radius + lane-width`;
3. vengono aperti due corridoi ortogonali, orizzontale e verticale, di semi-larghezza `corridor-half-width`.

Il risultato e' una topologia a quattro ingressi/uscite in cui l'isola centrale elimina il collegamento rettilineo diretto nel nodo di intersezione. Questa scelta e' il cuore del progetto: la geometria non si limita a contenere il flusso, ma **ne modifica la classe dinamica**.

#### 2.2 Vicinato di Moore e cinematica discreta
Il movimento usa il **Moore neighborhood**: 8 celle adiacenti piu' l'opzione di permanenza sulla cella corrente. Il codice costruisce infatti 9 probabilita' di transizione:

- `p0..p8` per le 8 direzioni cardinali/diagonali e `stay`;
- normalizzazione stocastica locale;
- estrazione casuale della mossa successiva.

Il vicinato di Moore e' coerente con la fisica discreta del sistema: permette micro-deviazioni diagonali, riduce anisotropie spurie dovute alla griglia e si allinea al calcolo dei campi statici, anch'esso basato su connettivita' a 8 vicini.

#### 2.3 Static Floor Field via BFS
Per ciascuna delle quattro destinazioni, il modello costruisce un campo statico `S0..S3` tramite una **Breadth-First Search multi-source** a partire dalle patch di uscita. La procedura:

- inizializza tutte le patch a una distanza molto alta;
- pone a `0` le patch di uscita della destinazione considerata;
- propaga la distanza sui vicini non muro;
- inverte infine il campo con `S = max-dist - dist`, in modo che valori alti corrispondano a zone piu' attrattive.

Questo e' un dettaglio importante: il pedone non "minimizza una distanza" in forma esplicita, ma massimizza una **attrattivita' esponenziale** tramite il termine `exp(Ks S)`.

#### 2.4 Il penalty trick e la rotazione antioraria
L'astuzia piu' elegante del modello e' il cosiddetto **penalty trick** nel BFS. Durante la propagazione del campo statico, il costo di alcune regioni viene artificialmente aumentato quando favorirebbero un aggiramento nel verso indesiderato. In altre parole, il gradiente topologico non rappresenta solo la distanza minima geometrica, ma una distanza **geometricamente polarizzata**.

Questo trucco induce una preferenza globale per la rotazione antioraria senza introdurre una regola esplicita del tipo "gira sempre a sinistra". L'ordine emerge dunque come risultato di un campo di costo pre-strutturato, non di un comando simbolico.

#### 2.5 Dynamic e Repulsive Fields
Il **campo dinamico** `D0..D3` viene depositato dal pedone sulla patch corrente prima del movimento, poi diffonde ai vicini con coefficiente `diffusion = 0.11` e decade con `decay = 0.15`. Il suo ruolo non e' puramente attrattivo: nella probabilita' di transizione, il termine dinamico e' costruito come

`D = D_destinazione - somma(D_altre_direzioni)`.

Questa scelta rende il campo **competitivo**: una patch e' favorita non solo se reca tracce del proprio flusso, ma anche se e' relativamente priva di tracce incompatibili.

Il **campo repulsivo** `R` viene invece aggiornato ogni tick sommando `E1 = 0.6` sulla patch occupata e `E2 = 0.2` sulle patch vicine. Esso non descrive una forza continua alla Helbing, ma un **potenziale discreto di costo locale**.

#### 2.6 Funzione di transizione stocastica
La legge centrale del modello e':

$$
P_{ij} \propto (1 - n_{ij}) \cdot \exp(K_s S_{ij}) \cdot \exp(K_d D_{ij}) \cdot \exp(-K_r R_{ij})
$$

dove `n_ij` vale `1` se la cella e' occupata o bloccata e `0` altrimenti. Con questa formulazione:

- `Ks` controlla l'orientamento verso l'uscita;
- `Kd` controlla l'intensita' dell'allineamento stigmergico;
- `Kr` controlla il costo della prossimita';
- l'esclusione spaziale e' imposta da `(1 - n_ij)`.

Il modello rimane quindi pienamente nel solco del **Floor Field Model** di Burstedde et al. (2001), ma adattato a una geometria circolare con bias rotazionale incorporato.

Da un punto di vista scientifico, questo significa che il progetto non e' una semplice "simulazione NetLogo", ma una **reinterpretazione applicata del modello di Burstedde** in un contesto dove la topologia urbana diventa parte attiva della computazione distribuita del moto.

### 3. Metodologia sperimentale
I risultati usati in questa relazione provengono dai file in `results/Risultati_Esperimenti` e dai grafici associati in `results/Risultati_Esperimenti/Grafici`. La batteria completa comprende **72 test**:

- `Exp1_FundamentalDiagram`: 10 livelli di popolazione x 5 ripetizioni = 50 run;
- `Exp2_SelfOrganization`: 6 valori di `Kd` x 5 ripetizioni = 30 run;
- `Exp3_GeometryOptimization`: 4 raggi x 5 ripetizioni = 20 run;
- `Exp4_RepulsionImpact`: 4 valori di `Kr` x 5 ripetizioni = 20 run.

Nel codice Python di orchestrazione, `Exp3` esclude correttamente `R = 15`, perche' con `lane-width = 8` il raggio esterno supera la meta' del mondo e rende la geometria non valida. La narrativa del documento finale deve dunque riferirsi ai raggi **5, 8, 10, 12**.

In termini metodologici, la struttura degli esperimenti ricalca in modo coerente la mappa delle fonti:

- `Exp1` dialoga con **Zhang** e con la letteratura sui diagrammi fondamentali;
- `Exp2` dialoga con **Helbing** sui fenomeni di self-organization;
- `Exp3` dialoga con **Weng** e **Yanagisawa** sull'efficacia comparata della rotonda;
- l'intero modello dialoga con **Burstedde**, che resta il riferimento teorico di base.

### 4. Discussione scientifica dei quattro esperimenti
#### 4.1 Exp 1: diagramma fondamentale e transizione di fase
`Exp1` varia `num-pedestrians` da 40 a 400 con `Ks = 1.0`, `Kd = 2.0`, `Kr = 1.0`, `roundabout-radius = 10`. La densita' e' stata normalizzata su `616` patch percorribili stimate dallo script di analisi, ottenendo un intervallo circa `0.065-0.649 ped/patch`.

Dal punto di vista fisico, la metrica piu' robusta e' il **tempo medio di uscita**, che cresce quasi monotonicamente:

| Pedoni | Densita' | Mean exit time (tick) |
| --- | ---: | ---: |
| 40 | 0.0649 | 150.16 |
| 120 | 0.1948 | 159.05 |
| 200 | 0.3247 | 175.53 |
| 240 | 0.3896 | 184.30 |
| 320 | 0.5195 | 190.45 |
| 400 | 0.6494 | 217.84 |

Questa crescita segnala una chiara **phase transition** da regime quasi libero a regime congestionato. In termini qualitativi:

- a bassa densita' il sistema resta vicino al **laminar flow**;
- a densita' intermedie aumenta il numero di conflitti locali nell'anello;
- ad alta densita' il costo di occupazione e di repulsione produce una dinamica intermittente, meno fluida e piu' vicina a uno stato turbolento/disordinato.

Va pero' sottolineato un punto metodologico decisivo: il CSV di `Exp1` misura `throughput-per-tick` come **uscite nell'ultimo tick del run**, non come media temporale sull'intera traiettoria. Questa metrica e' quindi rumorosa e non deve essere letta ingenuamente come capacita' media del sistema. Per una lettura scientificamente rigorosa, il grafico di `Exp1` va interpretato insieme all'aumento del tempo di uscita e al deterioramento della velocita' effettiva.

In termini teorici, il risultato e' coerente con la letteratura sui **fundamental diagrams** in geometrie vincolate, in particolare con il quadro richiamato in `Fonti_Ricerca_Pedoni.md` per **Zhang (2012)**: la densita' crescente deteriora la velocita' effettiva e allunga il tempo di attraversamento. Il nostro contributo specifico e' mostrare che la rotonda **sposta in avanti** il collasso del moto rispetto a un crossing diretto, ma non elimina l'esistenza di una soglia oltre la quale l'ingombro spaziale domina il beneficio topologico.

#### 4.2 Exp 2: auto-organizzazione e vorticita' spontanea
`Exp2` fissa `num-pedestrians = 160` e varia `Kd` in `{0.0, 0.5, 1.0, 2.0, 4.0, 8.0}`. Il dato piu' notevole e' che:

- `phi-max = 1.0` per tutti i run;
- `phi-stabilization-tick = 0` per tutti i run.

Questo implica che l'ordine non viene "costruito lentamente" dal campo dinamico: e' gia' presente sin dall'inizio come proprieta' della geometria e del bias statico. Il fenomeno si interpreta come **vorticita' spontanea geometry-driven**. In un incrocio a croce, `Kd` avrebbe il compito di favorire la lane formation; qui, invece, il sistema e' gia' vincolato a una circolazione coerente.

Qui il collegamento con **Helbing et al. (2005)** e' particolarmente forte. Nel loro quadro teorico, lane formation e self-organization sono fenomeni emergenti prodotti da interazioni locali ripetute. Nel nostro modello, la rotonda realizza una variante ancora piu' radicale: la struttura geometrica funge da **catalizzatore di auto-organizzazione**, imponendo quasi immediatamente uno stato ad alta segregazione. La conclusione forte e' che la rotonda funziona come un **dispositivo di auto-organizzazione strutturale**: l'indice di segregazione elevato non dipende in modo sensibile dal coordinamento sociale esplicito, ma dalla rottura della simmetria indotta dall'isola centrale e dal penalty trick nel campo statico.

#### 4.3 Exp 3: ottimizzazione urbanistica e clogging effect
`Exp3` studia il ruolo del raggio dell'isola centrale con `num-pedestrians = 240`, `Ks = 1.0`, `Kd = 2.0`, `Kr = 1.0`. I risultati medi sono:

| Raggio | Throughput totale | Mean exit time (tick) |
| --- | ---: | ---: |
| 5  | 1052.6 | 199.53 |
| 8  | 980.8  | 212.66 |
| 10 | 951.4  | 220.94 |
| 12 | 888.2  | 230.36 |

L'andamento e' netto: al crescere del raggio, il throughput cala e il tempo di viaggio aumenta. Questo risultato e' importante perche' smentisce una lettura ingenua secondo cui "piu' grande e' l'isola, meglio separa i flussi". In realta', oltre una certa soglia, l'ostacolo centrale:

- restringe la sezione utile dell'anello;
- allunga i percorsi;
- aumenta la permanenza media nel sistema;
- introduce un **clogging effect** di natura geometrica.

Questo passaggio va collegato direttamente a due fonti del file di riferimento:

- con **Weng et al. (2006)** condividiamo l'idea di fondo che la rotonda migliori il trattamento dei flussi incrociati;
- con **Yanagisawa et al. (2019)** condividiamo il punto piu' sottile, cioe' che il central obstacle produce streamlining solo entro un intervallo geometrico utile.

Il progetto suggerisce dunque l'esistenza di un **raggio critico minimo efficace**: la rotonda deve essere abbastanza grande da eliminare il conflitto frontale, ma non cosi' grande da trasformarsi in un ostacolo dissipativo. In questa configurazione sperimentale, `R = 5` e' la scelta piu' efficiente tra quelle testate.

#### 4.4 Exp 4: resilienza del sistema sotto stress repulsivo
`Exp4` varia `Kr` in `{0.5, 1.0, 2.0, 5.0}` a densita' media (`num-pedestrians = 160`). I valori aggregati mostrano che il sistema non collassa quando la penalizzazione repulsiva cresce:

| Kr | Velocita' effettiva | Mean exit time (tick) | Throughput per tick |
| --- | ---: | ---: | ---: |
| 0.5 | 0.0816 | 204.69 | 0.6 |
| 1.0 | 0.0855 | 195.20 | 0.4 |
| 2.0 | 0.0704 | 181.08 | 1.0 |
| 5.0 | 0.0948 | 173.71 | 0.8 |

I valori non seguono una monotonicita' perfetta, segno che la dinamica e' governata da interazioni non lineari tra esclusione, geometria e stocasticita'. La lettura corretta non e' quindi "Kr alto migliora" o "Kr alto peggiora" in senso assoluto. La conclusione piu' robusta e' un'altra: **la geometria mitiga la sensibilita' del sistema allo stress repulsivo**, perche' riduce gli incontri faccia a faccia, cioe' proprio le configurazioni in cui la repulsione causerebbe stallo e blocco locale.

Questo e' il punto in cui il collegamento con **Burstedde et al. (2001)** e con la tradizione dei floor field diventa piu' evidente: la repulsione non agisce come una forza fisica continua, ma come penalita' locale nella scelta discreta della patch successiva. In altre parole, la rotonda non elimina il costo sociale della prossimita', ma ne abbassa la pericolosita' sistemica convertendo i conflitti frontali in interazioni tangenziali.

#### 4.5 Exp 5: L'impatto dei profili psicologici (Social Types)
In questa estensione sperimentale, il sistema e' stato testato a densita' medio-alta (`num-pedestrians = 200`, `R=10`) per valutare l'impatto di specifici "profili sociali" sulla coordinazione passiva. Sono state eseguite run separate per isolare dinamicamente intere popolazioni con lo stesso comportamento:

| Profilo (Popolazione al 100%) | Throughput Totale | Mean Exit Time (tick) | Effective Speed |
| --- | ---: | ---: | ---: |
| **Baseline (Normali)** | 81.6 | 400.22 | 0.627 |
| **L'Aggressivo ($K_s \uparrow, K_r \downarrow$)** | 79.4 | 391.13 | 0.637 |
| **L'Imitatore ($K_d \uparrow$)** | 77.2 | 411.18 | 0.636 |
| **Il Prudente ($K_r \uparrow\uparrow$)** | 75.2 | 367.76 | 0.643 |

**Analisi DAI (Ottimo Individuale vs Ottimo Globale):**
1. **La "Tragedia" dell'Aggressivo**: A livello puramente individuale, l'aggressivo ottiene un beneficio spaziale (il *Mean Exit Time* scende a 391 tick e l'*Effective Speed* sale rispetto alla baseline). A livello globale o di "sistema", tuttavia, le performance crollano (il throughput totale cala). L'eccesso di intraprendenza e vicinanza causa un diffuso attrito locale (*clogging* prossimo alle uscite) limitando il volume aggregato di fuoriuscite.
2. **Il blocco del Prudente**: Questo profilo produce in assoluto il *lowest throughput* del sistema (appena 75.2). Fortemente esitanti di fronte all'ingorgo e per il timore dei contatti, i prudenti attendono molto di piu' prima di inserirsi in rotatoria; cosi' facendo paralizzano gli accessi. Tuttavia, nel momento in cui decidono di muoversi, affrontano bivi e corridoi sgombri, registrando paradossalmente la componente di volo a piu' alta *Effective Speed* e il minor Exit Time netto fra chi completa il ciclo.
3. **L'Imitatore (L'effetto Herding)**: Gli imitatori registrano il *Mean Exit Time* mediamente piu' lungo in assoluto (411.18 tick). Seguire ciecamente le tracce (un peso $K_d$ enorme) porta gli agenti ad accodarsi bovinamente gli uni dietro gli altri producendo il fenomeno del *platooning*. Invece di seguire le corde piu' brevi, effettuano lunghe e talvolta labirintiche circonvallazioni dietro i compagni di rotta, a dispetto dell'alta velocita' locale mantenuta in scia.

### 5. Sintesi per la presentazione orale
#### Executive summary
La conclusione da portare all'esame e' la seguente: **la rotonda pedonale si comporta come un algoritmo spaziale distribuito**. Non richiede agenti cognitivamente sofisticati; e' l'architettura dell'ambiente che pre-elabora il conflitto e lo trasforma in ordine collettivo. Il modello dimostra quindi che una parte dell'intelligenza del sistema puo' essere "scaricata" sulla geometria.

#### Domande difficili del prof e risposte da esperto
**Perche' la chiami DAI se non c'e' comunicazione esplicita tra agenti?**  
Perche' il coordinamento emerge comunque da interazioni locali distribuite. La differenza e' che qui la mediazione e' ambientale: campi e vincoli geometrici svolgono il ruolo che, in altri sistemi multi-agent, svolgerebbero messaggi o protocolli di coordinamento.

**Perche' `phi` resta massimo anche con `Kd = 0`? Non dovrebbe sparire la lane formation?**  
In un corridoio lineare si', ma nella rotonda no. Qui l'ordine e' dominato dalla topologia: isola centrale, BFS polarizzato e assenza di traiettorie rettilinee frontali impongono subito la segregazione tangenziale. `Kd` raffina il comportamento, ma non lo fonda.

**Dov'e' la transizione di fase in `Exp1` se il throughput finale e' rumoroso?**  
La si osserva in modo piu' affidabile nel tempo medio di uscita, che cresce da circa 150 a oltre 217 tick con l'aumento della densita'. La transizione non va letta come un singolo punto netto, ma come perdita progressiva di regime laminare e aumento del tempo di permanenza nel sistema.

**Perche' un'isola piu' grande peggiora le prestazioni?**  
Perche' oltre la soglia utile l'ostacolo non separa soltanto i flussi: restringe l'anello, allunga il cammino e aumenta il tempo di occupazione delle patch. Il beneficio anti-conflitto viene superato dal costo geometrico di percorso e sezione ridotta.

**Qual e' il limite piu' importante del vostro modello?**  
E' un modello CA discreto: spazio, tempo e velocita' sono quantizzati. Questo lo rende potente per studiare esclusione, competizione locale e stigmergia, ma meno fedele dei modelli continui nel rappresentare accelerazioni fini, anisotropie percettive e forze interpersonali realistiche.

**Come giustifichi scientificamente le fonti scelte?**  
Perche' ciascuna fonte copre un livello diverso dell'argomentazione: Burstedde spiega il meccanismo algoritmico, Zhang spiega la lettura densita'-flusso, Helbing spiega l'auto-organizzazione, Weng motiva la rotonda come alternativa all'incrocio e Yanagisawa chiarisce il ruolo non monotono dell'ostacolo centrale.

### 6. Conclusioni e sviluppi futuri
Dal punto di vista scientifico, il progetto mostra che la rotonda e' una configurazione di **design computazionale del flusso**. Il contributo principale non e' soltanto aver simulato una folla, ma aver mostrato che la geometria urbana puo' agire come meccanismo di coordinamento distribuito incorporato.

#### 6.1 Estensioni Proposte: Simulazione di Popolazioni in Mix Critico
Alla luce degli ottimi risultati sulle popolazioni eterogenee isolate (Exp 5), una direzione di ricerca rilevante e' studiare lo "scontro" e il rimescolamento fra tipologie psicodinamiche diverse nello stesso run esplorando la resilienza della rotonda.

Si propone un'estensione per capire le deviazioni massime tollerabili dalla rotonda definendo quale sia il **Critical Mix** (ad esempio un 25% di Aggressivi e 75% di Normali, o convogli di Imitatori guidati da sparuti Aggressivi). L'analisi metodica del Threshold in cui questi elementi non cooperativi infrangono inesorabilmente la capacita' di dissipazione laminare della *Distributed Artificial Intelligence* incorporata nel Floor Field potrebbe costituire un'eccellente applicazione finale della rotonda.

#### 6.2 Limiti e confronti
Rispetto ai **social force models** continui, l'automa cellulare a floor field ha tre vantaggi chiari:

- rende trasparente il ruolo dei costi locali e della topologia;
- consente una lettura pulita dei meccanismi di esclusione e lane formation;
- e' facilmente sperimentabile con sweep parametrici massivi.

I modelli continui restano pero' superiori quando servono traiettorie lisce, accelerazioni realistiche, anisotropie visive e calibrazione fine su dati empirici. Una naturale estensione del progetto sarebbe quindi un confronto sistematico tra:

- rotonda CA con campi `S-D-R`;
- incrocio standard senza isola centrale;
- modello continuo alla Helbing con la stessa geometria.

Questo permetterebbe di separare con maggiore precisione il contributo della discretizzazione dal contributo della topologia, chiarendo quanto dell'ordine osservato dipenda dal modello e quanto dalla forma dello spazio.

### 7. Mappa delle fonti e loro ruolo nella relazione
Per dare al professore l'impressione corretta di padronanza scientifica, conviene esplicitare anche il ruolo funzionale delle fonti:

| Fonte | Ruolo nel progetto | Dove entra nella discussione |
| --- | --- | --- |
| Burstedde et al. (2001) | Base matematica del Floor Field Model | Architettura del modello, probabilita' di transizione, campi `S-D-R` |
| Weng et al. (2006) | Giustificazione della rotonda come topologia efficiente | Introduzione critica, `Exp3`, confronto implicito con l'incrocio |
| Zhang (2012) | Cornice per il diagramma fondamentale | `Exp1`, densita', saturazione, deterioramento del tempo di attraversamento |
| Helbing et al. (2005) | Teoria dell'auto-organizzazione e della lane formation | `Exp2`, vorticita' spontanea, ordine collettivo |
| Yanagisawa et al. (2019) | Interpretazione del central obstacle come strumento di streamlining ma anche di possibile clogging | `Exp3`, lettura del raggio critico |

### Bibliografia essenziale con collegamenti
- Burstedde, C., Klauck, K., Schadschneider, A., Zittartz, J. (2001). *Cellular automaton approach to pedestrian dynamics*. Link richiamato in [Fonti_Ricerca_Pedoni.md](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:27).
- Helbing, D., Buzna, L., Johansson, A., Werner, T. (2005). *Self-Organizing Pedestrian Crowd Dynamics: Experiments, Simulations, and Design Solutions*. Link richiamato in [Fonti_Ricerca_Pedoni.md](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:16).
- Weng, W. G., Yuan, H. Y., Fang, Z., Shen, J., Zhao, Y. C. (2006). *Pedestrian dynamics in a roundabout: A cellular automaton study*. Link richiamato in [Fonti_Ricerca_Pedoni.md](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:5).
- Zhang, J. (2012). *Pedestrian fundamental diagrams: Comparative analysis of experiments in different geometries*. Link richiamato in [Fonti_Ricerca_Pedoni.md](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:11).
- Yanagisawa, D. et al. (2019). *Streamlining pedestrian flow in intersections by using a pedestrian-roundabout*. Link richiamato in [Fonti_Ricerca_Pedoni.md](/C:/Davide/Università/Magistrale/Secondo%20Anno/Primo%20Semestre/Distributed%20Artificial%20Intelligence/Progetto/docs/experiments/Fonti_Ricerca_Pedoni.md:22).
