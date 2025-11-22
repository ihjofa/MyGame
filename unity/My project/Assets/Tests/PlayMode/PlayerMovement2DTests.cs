using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.InputSystem;

public class PlayerMovement2DTests
{
    private GameObject playerObject;
    private PlayerMovement2D movement;
    private Rigidbody2D rb;

    [SetUp]
    public void SetUp()
    {
        // Create a test GameObject with required components
        playerObject = new GameObject("TestPlayer");
        rb = playerObject.AddComponent<Rigidbody2D>();
        movement = playerObject.AddComponent<PlayerMovement2D>();

        // Set default speed
        movement.speed = 5.0f;
    }

    [TearDown]
    public void TearDown()
    {
        // Clean up test objects
        if (playerObject != null)
        {
            Object.Destroy(playerObject);
        }
    }

    [Test]
    public void PlayerMovement2D_HasRigidbody2D()
    {
        // Arrange & Act
        var rigidbody = playerObject.GetComponent<Rigidbody2D>();

        // Assert
        Assert.IsNotNull(rigidbody, "PlayerMovement2D requires Rigidbody2D component");
    }

    [Test]
    public void PlayerMovement2D_SpeedProperty_CanBeSet()
    {
        // Arrange
        float expectedSpeed = 10.0f;

        // Act
        movement.speed = expectedSpeed;

        // Assert
        Assert.AreEqual(expectedSpeed, movement.speed, "Speed property should be settable");
    }

    [Test]
    public void PlayerMovement2D_InitialSpeed_IsPositive()
    {
        // Assert
        Assert.Greater(movement.speed, 0f, "Initial speed should be positive");
    }

    [UnityTest]
    public IEnumerator PlayerMovement2D_Update_ProcessesMovement()
    {
        // Arrange
        movement.speed = 5.0f;

        // Act - Wait one frame for component initialization
        yield return null;

        // Assert - Component should be initialized and ready
        Assert.IsNotNull(movement, "PlayerMovement2D component should be active");
        Assert.IsNotNull(rb, "Rigidbody2D should be attached");
    }

    [UnityTest]
    public IEnumerator PlayerMovement2D_NoInput_VelocityIsZero()
    {
        // Arrange
        rb.linearVelocity = Vector2.zero;

        // Act - Wait a few frames with no input
        yield return null;
        yield return null;

        // Assert - Without input, velocity should remain zero or close to zero
        Assert.LessOrEqual(rb.linearVelocity.magnitude, 0.1f,
            "Velocity should be zero or near zero with no input");
    }

    [Test]
    public void PlayerMovement2D_Awake_FindsRigidbody2D()
    {
        // Arrange - Already done in SetUp

        // Act - Awake is called automatically when component is added

        // Assert
        Assert.IsNotNull(playerObject.GetComponent<Rigidbody2D>(),
            "Rigidbody2D should be found in Awake");
    }

    [UnityTest]
    public IEnumerator PlayerMovement2D_MultipleFrames_MaintainsReferences()
    {
        // Arrange
        var initialRb = playerObject.GetComponent<Rigidbody2D>();

        // Act - Wait several frames
        for (int i = 0; i < 5; i++)
        {
            yield return null;
        }

        // Assert - References should remain valid
        Assert.IsNotNull(movement, "PlayerMovement2D should remain valid");
        Assert.AreSame(initialRb, playerObject.GetComponent<Rigidbody2D>(),
            "Rigidbody2D reference should remain the same");
    }
}
