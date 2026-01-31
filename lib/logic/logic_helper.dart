
class AmericanoLogic {
  // 1. РАСЧЕТ МЕСТ И ЛИСТА ОЖИДАНИЯ
  static Map<String, dynamic> calculateCapacity(int courts, int playersCount) {
    int maxPlayers = courts * 4;
    int waitlistCount = playersCount > maxPlayers ? playersCount - maxPlayers : 0;
    bool isFull = playersCount >= maxPlayers;
    
    return {
      'maxPlayers': maxPlayers,
      'waitlist': waitlistCount,
      'isFull': isFull,
    };
  }

  // 2. ГЕНЕРАЦИЯ ПАР ДЛЯ СТАНДАРТНОГО АМЕРИКАНО (Каждый с каждым)
  static List<Map<String, dynamic>> generateStandardRounds(List<String> playerIds) {
    List<Map<String, dynamic>> rounds = [];
    // Алгоритм Round Robin для смены партнеров
    // В упрощенном виде для MVP: перемешиваем и делим на 4
    playerIds.shuffle();
    
    for (int i = 0; i < playerIds.length; i += 4) {
      if (i + 3 < playerIds.length) {
        rounds.add({
          'court': (i / 4).toInt() + 1,
          'teamA': [playerIds[i], playerIds[i + 1]],
          'teamB': [playerIds[i + 2], playerIds[i + 3]],
          'status': 'READY'
        });
      }
    }
    return rounds;
  }

  // 3. ПРАВИЛО ОТМЕНЫ (Проверка времени)
  static bool canCancelWithoutPenalty(DateTime startTime, int limitHours) {
    final now = DateTime.now();
    final difference = startTime.difference(now).inHours;
    return difference >= limitHours;
  }
}