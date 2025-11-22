# PlayerMovement2D アクティビティ図

WASD入力による2D移動の処理フローを示します。

```mermaid
flowchart TD
    Start([ゲーム開始]) --> Awake[Awake: Rigidbody2D取得]
    Awake --> OnEnable[OnEnable: Input Action有効化]
    OnEnable --> WaitFrame{Update待機}

    WaitFrame --> Update[Update呼び出し]
    Update --> ReadInput[Input Actionから移動ベクトル読み取り]
    ReadInput --> CheckInput{入力があるか？}

    CheckInput -->|Yes| CalculateVelocity[速度ベクトル計算<br/>direction * speed]
    CheckInput -->|No| SetZeroVelocity[速度をゼロに設定]

    CalculateVelocity --> ApplyVelocity[Rigidbody2D.velocityに適用]
    SetZeroVelocity --> ApplyVelocity

    ApplyVelocity --> WaitFrame

    WaitFrame --> OnDisable[OnDisable: Input Action無効化]
    OnDisable --> End([終了])

    style Start fill:#90EE90
    style End fill:#FFB6C1
    style ReadInput fill:#87CEEB
    style ApplyVelocity fill:#FFD700
```

## 処理詳細

### 初期化フェーズ
1. **Awake**: 必要なコンポーネント（Rigidbody2D）を取得
2. **OnEnable**: Input Actionを有効化し、入力イベントの受信を開始

### 更新フェーズ（毎フレーム）
1. **入力読み取り**: Input Systemから移動ベクトル（Vector2）を取得
2. **速度計算**: 入力方向 × 速度プロパティ
3. **物理適用**: Rigidbody2Dのvelocityプロパティに設定

### 終了フェーズ
1. **OnDisable**: Input Actionを無効化し、リソースを解放
