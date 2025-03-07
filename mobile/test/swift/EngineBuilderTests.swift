@testable import Envoy
import EnvoyEngine
import Foundation
import XCTest

// swiftlint:disable type_body_length

private struct TestFilter: Filter {}

final class EngineBuilderTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    MockEnvoyEngine.onRunWithConfig = nil
    MockEnvoyEngine.onRunWithYAML = nil
  }

  func testSetRuntimeGuard() {
    let bootstrapDebugDescription = EngineBuilder()
      .setRuntimeGuard("test_feature_false", true)
      .setRuntimeGuard("test_feature_true", false)
      .bootstrapDebugDescription()
    XCTAssertTrue(
      bootstrapDebugDescription.contains(#""test_feature_false" value { bool_value: true }"#)
    )
    XCTAssertTrue(
      bootstrapDebugDescription.contains(#""test_feature_true" value { bool_value: false }"#)
    )
  }

  func testPlatformCertificateValidationAlwaysEnabled() {
    let bootstrapDebugDescription = EngineBuilder()
      .bootstrapDebugDescription()
    XCTAssertTrue(
      bootstrapDebugDescription
        .contains("envoy_mobile.cert_validator.platform_bridge_cert_validator")
    )
  }

  func testMonitoringModeDefaultsToPathMonitor() {
    let builder = EngineBuilder()
    XCTAssertEqual(builder.monitoringMode, .pathMonitor)
  }

  func testMonitoringModeSetsToValue() {
    let builder = EngineBuilder()
      .setNetworkMonitoringMode(.disabled)
    XCTAssertEqual(builder.monitoringMode, .disabled)
    builder.setNetworkMonitoringMode(.reachability)
    XCTAssertEqual(builder.monitoringMode, .reachability)
  }

  func testCustomConfigYAMLUsesSpecifiedYAMLWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithYAML = { yaml, _, _ in
      XCTAssertEqual("foobar", yaml)
      expectation.fulfill()
    }

    _ = EngineBuilder(yaml: "foobar")
      .addEngineType(MockEnvoyEngine.self)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingLogLevelAddsLogLevelWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { _, logLevel in
      XCTAssertEqual("trace", logLevel)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addLogLevel(.trace)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAdminInterfaceIsDisabledByDefault() {
    let expectation = self.expectation(description: "Run called with disabled admin interface")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertFalse(config.adminInterfaceEnabled)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

#if ENVOY_ADMIN_FUNCTIONALITY
  func testEnablingAdminInterfaceAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with enabled admin interface")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertTrue(config.adminInterfaceEnabled)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .enableAdminInterface()
      .build()
    self.waitForExpectations(timeout: 0.01)
  }
#endif

  func testEnablingHappyEyeballsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with enabled happy eyeballs")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertTrue(config.enableHappyEyeballs)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .enableHappyEyeballs(true)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testEnablingInterfaceBindingAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with enabled interface binding")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertTrue(config.enableInterfaceBinding)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .enableInterfaceBinding(true)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testEnforcingTrustChainVerificationAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with enforced cert verification")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertTrue(config.enforceTrustChainVerification)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .enforceTrustChainVerification(true)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testForceIPv6AddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with force IPv6")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertTrue(config.forceIPv6)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .forceIPv6(true)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddinggrpcStatsDomainAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual("stats.envoyproxy.io", config.grpcStatsDomain)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addGrpcStatsDomain("stats.envoyproxy.io")
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingConnectTimeoutSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(12345, config.connectTimeoutSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addConnectTimeoutSeconds(12345)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingDNSRefreshSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(23, config.dnsRefreshSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addDNSRefreshSeconds(23)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingDNSMinRefreshSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(23, config.dnsMinRefreshSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addDNSMinRefreshSeconds(23)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingDNSQueryTimeoutSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(234, config.dnsQueryTimeoutSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addDNSQueryTimeoutSeconds(234)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingDNSFailureRefreshSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(1234, config.dnsFailureRefreshSecondsBase)
      XCTAssertEqual(5678, config.dnsFailureRefreshSecondsMax)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addDNSFailureRefreshSeconds(base: 1234, max: 5678)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingH2ConnectionKeepaliveIdleIntervalMSAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(234, config.h2ConnectionKeepaliveIdleIntervalMilliseconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addH2ConnectionKeepaliveIdleIntervalMilliseconds(234)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingH2ConnectionKeepaliveTimeoutSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(234, config.h2ConnectionKeepaliveTimeoutSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addH2ConnectionKeepaliveTimeoutSeconds(234)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testSettingMaxConnectionsPerHostAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(23, config.maxConnectionsPerHost)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .setMaxConnectionsPerHost(23)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingPlatformFiltersToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(1, config.httpPlatformFilterFactories.count)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addPlatformFilter(TestFilter.init)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingStatsFlushSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(42, config.statsFlushSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addStatsFlushSeconds(42)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingStreamIdleTimeoutSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(42, config.streamIdleTimeoutSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addStreamIdleTimeoutSeconds(42)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingPerTryIdleTimeoutSecondsAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(21, config.perTryIdleTimeoutSeconds)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addPerTryIdleTimeoutSeconds(21)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingAppVersionAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual("v1.2.3", config.appVersion)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addAppVersion("v1.2.3")
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingAppIdAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual("com.envoymobile.ios", config.appId)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addAppId("com.envoymobile.ios")
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingVirtualClustersAddsToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(["test"], config.virtualClusters)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addVirtualClusters(["test"])
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingNativeFiltersToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual(1, config.nativeFilterChain.count)
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addNativeFilter(name: "test_name", typedConfig: "config")
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingStringAccessorToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual("hello", config.stringAccessors["name"]?.getEnvoyString())
      expectation.fulfill()
    }

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addStringAccessor(name: "name", accessor: { "hello" })
      .build()
    self.waitForExpectations(timeout: 0.01)
  }

  func testAddingRtdsAndAdsConfigurationWhenRunningEnvoy() {
    let bootstrapDebugDescription = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addRTDSLayer(name: "rtds_layer_name", timeoutSeconds: 14325)
      .setAggregatedDiscoveryService(address: "FAKE_SWIFT_ADDRESS", port: 0)
      .bootstrapDebugDescription()
    XCTAssertTrue(bootstrapDebugDescription.contains("rtds_layer_name"))
    XCTAssertTrue(bootstrapDebugDescription.contains("initial_fetch_timeout { seconds: 14325 }"))
    XCTAssertTrue(bootstrapDebugDescription.contains("FAKE_SWIFT_ADDRESS"))
  }

  func testDefaultValues() {
    // rtds, ads, node_id, node_locality
    let bootstrapDebugDescription = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .bootstrapDebugDescription()
    XCTAssertFalse(bootstrapDebugDescription.contains("rtds_layer:"))
    XCTAssertFalse(bootstrapDebugDescription.contains("ads_config:"))
    XCTAssertTrue(bootstrapDebugDescription.contains(#"id: "envoy-mobile""#))
    XCTAssertFalse(bootstrapDebugDescription.contains("locality:"))
  }

  func testCustomnodeID() {
    let bootstrapDebugDescription = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .setNodeID("SWIFT_TEST_NODE_ID")
      .bootstrapDebugDescription()
    XCTAssertTrue(bootstrapDebugDescription.contains(#"id: "SWIFT_TEST_NODE_ID""#))
  }

  func testCustomNodeLocality() {
    let bootstrapDebugDescription = EngineBuilder()
      .setNodeLocality(region: "SWIFT_REGION", zone: "SWIFT_ZONE", subZone: "SWIFT_SUB")
      .bootstrapDebugDescription()
    XCTAssertTrue(bootstrapDebugDescription.contains(#"region: "SWIFT_REGION""#))
    XCTAssertTrue(bootstrapDebugDescription.contains(#"zone: "SWIFT_ZONE""#))
    XCTAssertTrue(bootstrapDebugDescription.contains(#"sub_zone: "SWIFT_SUB""#))
  }

  func testAddingKeyValueStoreToConfigurationWhenRunningEnvoy() {
    let expectation = self.expectation(description: "Run called with expected data")
    MockEnvoyEngine.onRunWithConfig = { config, _ in
      XCTAssertEqual("bar", config.keyValueStores["name"]?.readValue(forKey: "foo"))
      expectation.fulfill()
    }

    let testStore: KeyValueStore = {
      class TestStore: KeyValueStore {
        private var dict: [String: String] = [:]

        func readValue(forKey key: String) -> String? {
          return dict[key]
        }

        func saveValue(_ value: String, toKey key: String) {
          dict[key] = value
        }

        func removeKey(_ key: String) {
          dict[key] = nil
        }
      }

      return TestStore()
    }()

    testStore.saveValue("bar", toKey: "foo")

    _ = EngineBuilder()
      .addEngineType(MockEnvoyEngine.self)
      .addKeyValueStore(name: "name", keyValueStore: testStore)
      .build()
    self.waitForExpectations(timeout: 0.01)
  }
}
