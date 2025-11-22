using UnityEngine;

/// <summary>
/// WASD入力による2D移動を制御するコンポーネント
/// Rigidbody2Dを使用した物理ベースの移動を実装
/// </summary>
[RequireComponent(typeof(Rigidbody2D))]
public class PlayerMovement2D : MonoBehaviour
{
    #region Serialized Fields

    /// <summary>
    /// 移動速度（単位: units/秒）
    /// </summary>
    [SerializeField]
    [Tooltip("移動速度（units/秒）")]
    public float speed = 5.0f;

    #endregion

    #region Private Fields

    /// <summary>
    /// Rigidbody2Dコンポーネントへの参照
    /// </summary>
    private Rigidbody2D rb;

    /// <summary>
    /// Input Systemの入力コントロール
    /// </summary>
    private PlayerControls controls;

    /// <summary>
    /// 現在の移動方向ベクトル
    /// </summary>
    private Vector2 moveDirection;

    #endregion

    #region Unity Lifecycle Methods

    /// <summary>
    /// 初期化処理
    /// </summary>
    private void Awake()
    {
        // Rigidbody2Dコンポーネントを取得
        rb = GetComponent<Rigidbody2D>();

        if (rb == null)
        {
            Debug.LogError("PlayerMovement2D requires a Rigidbody2D component!");
        }

        // PlayerControlsインスタンスを生成
        controls = new PlayerControls();
    }

    /// <summary>
    /// コンポーネント有効化時の処理
    /// </summary>
    private void OnEnable()
    {
        // Input Actionを有効化
        controls.Player.Enable();
    }

    /// <summary>
    /// コンポーネント無効化時の処理
    /// </summary>
    private void OnDisable()
    {
        // Input Actionを無効化
        controls.Player.Disable();
    }

    /// <summary>
    /// 毎フレームの更新処理
    /// </summary>
    private void Update()
    {
        // Input Actionから移動ベクトルを読み取り
        moveDirection = controls.Player.Move.ReadValue<UnityEngine.Vector2>();
    }

    /// <summary>
    /// 物理更新処理（移動の適用）
    /// </summary>
    private void FixedUpdate()
    {
        Move(moveDirection);
    }

    #endregion

    #region Movement Methods

    /// <summary>
    /// 指定された方向に移動
    /// </summary>
    /// <param name="direction">移動方向ベクトル（正規化不要）</param>
    private void Move(Vector2 direction)
    {
        if (rb == null)
        {
            return;
        }

        // 速度ベクトルを計算して適用
        Vector2 velocity = direction * speed;
        rb.linearVelocity = velocity;
    }

    #endregion

    #region Public Methods (Optional)

    /// <summary>
    /// 現在の移動速度を取得
    /// </summary>
    /// <returns>現在の速度ベクトル</returns>
    public Vector2 GetCurrentVelocity()
    {
        return rb != null ? rb.linearVelocity : Vector2.zero;
    }

    /// <summary>
    /// 移動を停止
    /// </summary>
    public void Stop()
    {
        if (rb != null)
        {
            rb.linearVelocity = Vector2.zero;
        }
    }

    #endregion
}
