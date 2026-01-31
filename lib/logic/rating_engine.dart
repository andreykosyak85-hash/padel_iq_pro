import 'dart:math';

class RatingEngine {
  /// Основная функция расчета изменения рейтинга (Delta)
  /// Входные рейтинги в формате 1.0–7.0.
  /// Внутри умножаются на 1000 для точности.
  static double calculateAdvancedDelta({
    required double currentRating,
    required double partnerRating,
    required double opponentAvgRating,
    required int gamesPlayed,
    required double reliability,
    required double stability,
    required int repetitionCount,
    required double groupTrust,
    required double formatWeight,
    required int result,
  }) {
    // Переводим в «очки»
    double pRating = currentRating * 1000;
    double partRating = partnerRating * 1000;
    double oppRating = opponentAvgRating * 1000;

    // Базовый K-фактор (динамический)
    double K = _calculateKFactor(gamesPlayed);

    // Ожидаемый результат (упрощённая формула Эло)
    double expected = 1 / (1 + pow(10, (oppRating - pRating) / 400));

    // Исходная дельта
    double delta = K * (result - expected);

    // Применяем модификаторы по порядку
    delta = _applyPartnerModifier(delta, pRating, partRating);
    delta = _applyAntiFarm(delta, repetitionCount);
    delta = _applyGroupTrust(delta, groupTrust);
    delta = _applyFormatWeight(delta, formatWeight);
    delta = _applyReliabilityStability(delta, reliability, stability);

    // Перевод обратно в шкалу 1.0–7.0
    double finalDelta = delta / 1000;

    // Минимальный шаг изменения рейтинга (не меньше ±0.002)
    finalDelta = _applyMinimumDelta(finalDelta, 0.002);

    // Ограничиваем итоговое изменение, чтобы избежать резких скачков
    return finalDelta.clamp(-0.15, 0.15);
  }

  /// K-Factor в зависимости от опыта
  static double _calculateKFactor(int gamesPlayed) {
    if (gamesPlayed < 10) return 60.0;
    if (gamesPlayed < 30) return 40.0;
    return 32.0;
  }

  /// Модификатор влияния партнёра
  static double _applyPartnerModifier(
      double delta, double pRating, double partRating) {
    double partnerDiff = partRating - pRating;
    if (partnerDiff > 200) {
      // Если партнёр намного сильнее — уменьшаем
      delta *= 0.9;
    } else if (partnerDiff < -200) {
      // Если партнёр слабее — увеличиваем
      delta *= 1.1;
    }
    return delta;
  }

  /// Антифарм: резкое снижение дельты при частой игре с теми же
  static double _applyAntiFarm(double delta, int repetitionCount) {
    if (repetitionCount > 5) {
      delta *= 0.5;
    } else if (repetitionCount > 3) delta *= 0.7;
    return delta;
  }

  /// Надёжность группы/матча
  static double _applyGroupTrust(double delta, double groupTrust) {
    return delta * (1 - (1 - groupTrust) * 0.3);
  }

  /// Вес формата (турнир / товарищеский)
  static double _applyFormatWeight(double delta, double formatWeight) {
    return delta * formatWeight;
  }

  /// Надёжность (reliability) и стабильность (stability)
  static double _applyReliabilityStability(
      double delta, double reliability, double stability) {
    // Надёжность: меньше роста при ненадёжном игроке
    delta *= (1 - (1 - reliability) * 0.4);
    // Стабильность: смягчает колебания
    delta *= (0.5 + stability * 0.5);
    return delta;
  }

  /// Минимальный шаг изменения рейтинга
  static double _applyMinimumDelta(double delta, double minStep) {
    if (delta.abs() < minStep) {
      return delta.isNegative ? -minStep : minStep;
    }
    return delta;
  }
}
