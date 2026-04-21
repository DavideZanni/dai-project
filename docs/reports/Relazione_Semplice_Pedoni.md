# Come si muovono i pedoni in una rotonda?
## Guida semplice al progetto di simulazione (Distributed AI)

### Cos'è questo progetto?
Immagina una rotonda stradale, ma usata dai pedoni invece che dalle auto. Questo progetto usa un software chiamato **NetLogo** per simulare come le persone attraversano un incrocio a quattro bracci se al centro mettiamo un'isola circolare.

L'idea principale è che la **forma della rotonda** aiuta le persone a non scontrarsi, agendo come una sorta di "vigile invisibile". In termini tecnici, chiamiamo questo sistema **Intelligenza Artificiale Distribuita Passiva**.

### 1. Il concetto: Il coordinamento senza parole
Di solito, per collaborare, le persone devono parlarsi o seguire segnali (come i semafori). In questo modello, i pedoni non comunicano tra loro. Il coordinamento nasce da due cose:
1.  **L'ambiente (la rotonda)**: La forma stessa della rotonda costringe le persone a girare in senso antiorario, separando chi va in direzioni diverse.
2.  **I segnali invisibili**: I pedoni lasciano "tracce" virtuali dove passano (come le briciole di pollicino) e cercano di stare lontani dagli altri per non urtarsi.

### 2. Come funziona "il cervello" dei pedoni?
Ogni pedone nella simulazione segue tre mappe mentali (chiamate **Floor Fields**):

*   **Mappa della Meta (Campo Statico)**: È come un navigatore GPS che dice al pedone qual è la strada più veloce per uscire. Abbiamo aggiunto un piccolo trucco: la strada "più veloce" per il GPS è sempre quella che passa per la rotonda in senso antiorario.
*   **Mappa della Scia (Campo Dinamico)**: I pedoni tendono a seguire la scia lasciata da chi sta andando nella loro stessa direzione. È quello che succede quando camminiamo in una strada affollata e ci mettiamo "in fila" dietro a qualcuno per fare meno fatica.
*   **Mappa dello Spazio Personale (Campo Repulsivo)**: Ognuno di noi ha una "bolla" invisibile; se qualcuno entra nella nostra bolla, cerchiamo di spostarci.

### 3. Cosa abbiamo scoperto con i test?
Abbiamo fatto correre la simulazione 72 volte cambiando diversi parametri. Ecco i risultati in parole semplici:

*   **Il traffico (Esperimento 1)**: Come previsto, più persone ci sono, più si cammina piano. Tuttavia, la rotonda regge bene il colpo finché non diventa davvero troppo affollata.
*   **L'ordine spontaneo (Esperimento 2)**: Anche se non diciamo ai pedoni di collaborare, dopo pochi secondi iniziano tutti a girare ordinatamente. È la forma della rotonda a "obbligarli" a essere ordinati.
*   **La misura giusta (Esperimento 3)**: Abbiamo scoperto che l'isola centrale non deve essere troppo grande. Se è troppo grande, le persone devono fare un giro troppo lungo e si creano ingorghi inutili. La misura "media" è la migliore.
*   **Tipi psicologici (Esperimento 5)**: Abbiamo provato a mettere solo persone "aggressive" (che corrono e se ne fregano degli altri) o solo persone "prudenti" (che si fermano appena vedono qualcuno).
    *   **Gli aggressivi**: Arrivano prima a destinazione individualmente, ma creano un caos totale per tutti gli altri.
    *   **I prudenti**: Non si scontrano mai, ma l'incrocio diventa lentissimo perché tutti aspettano troppo tempo prima di muoversi.

### 4. Conclusioni
La lezione più importante è che **il design dello spazio può sostituire la comunicazione**. Se progettiamo bene una piazza o una rotonda, le persone si coordineranno da sole in modo naturale e fluido, semplicemente seguendo la forma dell'ambiente e i piccoli segnali lasciati dagli altri.

---
*Nota: Questa è una versione semplificata della Relazione Tecnica Avanzata ad uso didattico.*
