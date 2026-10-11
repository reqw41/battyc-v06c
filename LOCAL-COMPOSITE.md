<!-- heavy-plan-current -->
Текущая композитная сборка: SHA256 `8b95fcdf5465959f965862b4f13d310ac3feb6d78db67f757fc6e86c4b5b8e28`. Актуальная память, SP-пары и замеры — в `HEAVY-FRAME-PLAN.txt` / `batty-heavy-frame-budget.txt`. Разделы ниже описывают предыдущие сборки.
<!-- /heavy-plan-current -->

# Experimental local composition

Current SHA256: `8c57b0b679ad7420f1e0812458cff3f1c2f8c722567ad287eb7d57f7e2b0fd93`.

See PREPARED-SPRITES.md for the current layout, cache format, tests and measurements. The compositor remains slower than the fast variant; destination-SP direct blits are used in the fast variant. The experiment retains adjacent E/F raster commits and same-player life resume.
