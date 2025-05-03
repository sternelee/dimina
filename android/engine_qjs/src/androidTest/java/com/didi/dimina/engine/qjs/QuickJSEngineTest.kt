package com.didi.dimina.engine.qjs

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Instrumented tests for QuickJSEngine
 * 
 * These tests run on an Android device or emulator, so they have access
 * to the native library.
 */
@RunWith(AndroidJUnit4::class)
class QuickJSEngineTest {
    
    private lateinit var jsEngine: QuickJSEngine
    
    @Before
    fun setUp() {
        // Create a new QuickJSEngine instance before each test
        jsEngine = QuickJSEngine()
    }
    
    @After
    fun tearDown() {
        // Clean up resources after each test
        if (::jsEngine.isInitialized) {
            // Even if the engine reports as not initialized, try to destroy it
            // to ensure all native resources are properly cleaned up
            jsEngine.destroy()
            
            // Add a small delay to allow GC to run
            Thread.sleep(100)
        }
    }
    
    @Test
    fun testSimpleJavaScriptExpression() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Execute simple JavaScript expression
        val simpleResult = jsEngine.evaluate("1 + 2 * 3")
        assertEquals(7, simpleResult.numberValue.toInt())
    }
    
    @Test
    fun testJavaScriptFunction() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Define and call a JavaScript function
        val functionScript = """
            function greet(name) {
                return 'Hello, ' + name + '!';
            }
            greet('Dimina');
        """.trimIndent()
        val functionResult = jsEngine.evaluate(functionScript)
        assertEquals("Hello, Dimina!", functionResult.stringValue)
    }
    
    @Test
    fun testJavaScriptObjects() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Work with JavaScript objects
        val objectScript = """
            const app = {
                name: 'Dimina',
                version: '1.0.0',
                getInfo: function() {
                    return this.name + ' v' + this.version;
                }
            };
            app.getInfo();
        """.trimIndent()
        val objectResult = jsEngine.evaluate(objectScript)
        assertEquals("Dimina v1.0.0", objectResult.stringValue)
    }
    
    @Test
    fun testTypedEvaluation() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Get typed result using evaluate
        // Wrap the object in parentheses to make it a valid expression
        val typedResult = jsEngine.evaluate("({ 'type': 'mini-program', 'active': true })")
        // Check that the result is correctly identified as an object
        assertEquals(JSValue.Type.OBJECT, typedResult.type)
        // Now we should get a proper JSON string representation of the object
        val resultStr = typedResult.toString()
        assertTrue("Result should contain 'type' property", resultStr.contains("type"))
        assertTrue("Result should contain 'mini-program' value", resultStr.contains("mini-program"))
        assertTrue("Result should contain 'active' property", resultStr.contains("active"))
        assertTrue("Result should contain 'true' value", resultStr.contains("true"))
    }
    
    @Test
    fun testEngineLifecycle() {
        // Test initialization
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        assertTrue("Engine should report as initialized", jsEngine.isInitialized())
        
        // Test destruction
        jsEngine.destroy()
        assertFalse("Engine should report as not initialized after destruction", jsEngine.isInitialized())
    }
    
    @Test
    fun testAsyncEvaluation() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Execute a simple JavaScript expression first to ensure the engine is working
        val simpleResult = jsEngine.evaluate("1 + 2")
        assertEquals(JSValue.Type.NUMBER, simpleResult.type)
        assertEquals("3.0", simpleResult.toString())
        
        // Execute a complex JavaScript computation asynchronously
        val script = """
            (() => {
                // Simple calculation for testing
                let result = 0;
                for (let i = 0; i < 100; i++) {
                    result += i;
                }
                return { sum: result, completed: true };
            })();
        """.trimIndent()
        
        // Use CountDownLatch to wait for async result
        val latch = CountDownLatch(1)
        val resultRef = AtomicReference<JSValue?>(null)

        // Use evaluateAsync to run the script in the dedicated JS thread
        jsEngine.evaluateAsync(script) { result ->
            // Print debug information
            println("AsyncResult type: ${result.type}")
            println("AsyncResult value: $result")
            
            resultRef.set(result)
            latch.countDown()
        }
        
        // Wait for the async result with a timeout
        assertTrue("Async evaluation timed out", latch.await(5, TimeUnit.SECONDS))

        // Get the result from the atomic reference
        val asyncResult = resultRef.get()!!
        
        // For now, let's modify the test to handle both OBJECT and ERROR types
        // This will help us understand if there's an intermittent issue
        if (asyncResult.type == JSValue.Type.OBJECT) {
            val resultStr = asyncResult.toString()
            assertTrue("Result should contain 'sum' property", resultStr.contains("sum"))
            assertTrue("Result should contain the correct sum value", resultStr.contains("4950")) // Sum of numbers 0-99
            assertTrue("Result should contain 'completed' property", resultStr.contains("completed"))
            assertTrue("Result should contain 'true' value", resultStr.contains("true"))
        } else {
            // Log the error but don't fail the test yet - we're debugging
            println("Error in async evaluation: $asyncResult")
            fail("Expected OBJECT type but got ${asyncResult.type}: $asyncResult")
        }
    }
    
    @Test
    fun testJavaScriptEventLoop() {
        // Initialize the engine
        val initialized = jsEngine.initialize()
        assertTrue("Engine should initialize successfully", initialized)
        
        // Single script that runs once and captures the event loop behavior
        val setupScript = """
            // Create a global object to store our test state
            if (typeof globalThis.__eventLoopTest === 'undefined') {
                globalThis.__eventLoopTest = {
                    executionOrder: [],
                    originalLog: console.log,
                    allDone: false,
                    promisesDone: false,
                    setupComplete: false
                };
                
                // Override console.log to capture the output
                console.log = function(msg) {
                    globalThis.__eventLoopTest.executionOrder.push(msg);
                    globalThis.__eventLoopTest.originalLog(msg);
                };
            }
            
            // Function to check if everything is done
            function checkAllDone() {
                if (globalThis.__eventLoopTest.allDone) {
                    return globalThis.__eventLoopTest.executionOrder;
                }
                
                // If not done yet, return a special marker
                return ["NOT_DONE_YET"];
            }
            
            // Only run the test once
            if (!globalThis.__eventLoopTest.setupComplete) {
                globalThis.__eventLoopTest.setupComplete = true;
                
                console.log("script start");
                
                // Create a Promise to track when all microtasks are done
                Promise.resolve()
                    .then(() => {
                        console.log("Promise 1");
                        return Promise.resolve();
                    })
                    .then(() => {
                        console.log("Promise 2");
                        globalThis.__eventLoopTest.promisesDone = true;
                    });
                
                // Simple nextTick implementation using Promise
                Promise.resolve().then(() => {
                    console.log("nextTick 1");
                    return Promise.resolve().then(() => {
                        console.log("nextTick 2");
                    });
                });
                
                console.log("script end");
                
                // Use setTimeout with a callback that marks completion
                setTimeout(() => {
                    console.log("setTimeout");
                    // After setTimeout executes, all operations should be complete
                    globalThis.__eventLoopTest.allDone = true;
                }, 0);
            }
            
            // Return the current state - the test will retry if needed
            checkAllDone();
        """.trimIndent()
        
        // Use a retry mechanism to wait for setTimeout to complete
        val maxRetries = 10
        var retries = 0
        var finalResult: JSValue? = null
        
        while (retries < maxRetries) {
            // Execute the script
            val result = jsEngine.evaluate(setupScript)
            println("Attempt ${retries + 1}: $result")
            
            // Check if we got a valid result with all operations completed
            if (result.toString().contains("setTimeout")) {
                finalResult = result
                break
            }
            
            // Wait a bit before retrying
            Thread.sleep(500)
            retries++
        }
        
        // Make sure we got a result
        assertNotNull("Failed to get a complete result after $maxRetries retries", finalResult)
        
        // Convert the result to a string and verify the execution order
        val resultStr = finalResult.toString()
        println("Final execution order: $resultStr")
        
        // Expected execution order based on JavaScript event loop behavior:
        val expectedOrder = listOf(
            "script start",
            "script end",
            "Promise 1",
            "nextTick 1",
            "nextTick 2",
            "Promise 2",
            "setTimeout"
        )
        
        // Verify the presence of all expected log messages
        for (message in expectedOrder) {
            assertTrue("Result should contain '$message'", resultStr.contains(message))
        }
        
        // Verify the correct order by checking relative positions in the string
        for (i in 0 until expectedOrder.size - 1) {
            val currentMessage = expectedOrder[i]
            val nextMessage = expectedOrder[i + 1]
            assertTrue(
                "'$currentMessage' should appear before '$nextMessage'", 
                resultStr.indexOf(currentMessage) < resultStr.indexOf(nextMessage)
            )
        }
    }
}
