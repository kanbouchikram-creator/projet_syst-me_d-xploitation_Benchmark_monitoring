# SysPerf Monitor 🚀

## 📌 Description
Ce projet permet de comparer les performances d’exécution de différentes méthodes :
- Séquentiel (seq)
- Parallélisme avec fork
- Threads
- Subshell

Il mesure :
- ⏱️ Temps d’exécution
- 💻 Utilisation CPU
- 🧠 Utilisation mémoire (RAM)

---

## ⚙️ Fonctionnalités

- Benchmark CPU
- Benchmark I/O
- Exécution de commandes personnalisées (ex: sleep)
- Monitoring système (CPU / RAM)
- Logs des résultats

---

## 🧪 Tests réalisés

### 🔹 CPU
```bash
./sysperf.sh -compare -task cpu -n 4 -monitor
