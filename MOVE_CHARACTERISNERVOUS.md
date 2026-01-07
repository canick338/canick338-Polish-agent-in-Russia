# ⚠️ ВАЖНО: Перемещение файла characterisnervous.ogv

## 📁 Правильная структура:

Файл `characterisnervous.ogv` должен быть в:
```
godot/Characters/Animations/Danila/nervous.ogv
```

А НЕ в:
```
godot/Cutscenes/characterisnervous.ogv
```

---

## 🔧 Как переместить (ВРУЧНУЮ):

### Способ 1: Через Проводник Windows

1. Откройте папку:
   ```
   C:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\Cutscenes\
   ```

2. Найдите файл: `characterisnervous.ogv`

3. Вырежьте (Ctrl+X) или скопируйте (Ctrl+C)

4. Перейдите в папку:
   ```
   C:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\Characters\Animations\Danila\
   ```

5. Вставьте (Ctrl+V)

6. Переименуйте в: `nervous.ogv`

---

### Способ 2: Через PowerShell (обычный терминал)

Откройте обычный PowerShell и выполните:

```powershell
cd "C:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main"

move "godot\Cutscenes\characterisnervous.ogv" "godot\Characters\Animations\Danila\nervous.ogv"
```

---

## ✅ После перемещения:

Файл будет использоваться автоматически когда вы напишете:
```
danila nervous "Я нервничаю!"
```

Система автоматически найдет `nervous.ogv` в папке `Danila/` и покажет анимацию!

---

## 📝 Обновление сценариев:

Все ссылки на `cutscene characterisnervous` в тестовых файлах можно оставить как есть для полноэкранных кат-сцен, или заменить на:
```
danila nervous "Текст"
```
для анимированного портрета.










