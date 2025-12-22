//
//  ContentView.swift
//  Allons-Y    
//
//  Created by Mike Nibeck on 12/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SceneViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top: SceneKit 3D view
            SceneKitView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .frame(height: 450)
                .background(Color(.systemBackground))
                .overlay(alignment: .topLeading) {
                    Text("Alons-Y")
                        .font(.caption)
                        .padding(6)
                        .background(.thinMaterial, in: .capsule)
                        .padding(8)
                }

            Divider()

            // Bottom: SwiftUI controls
            controls
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                //Text("3D Model Controls").font(.headline)

                Group {
                    LabeledContent("Rotation X") {
                        Slider(value: $viewModel.rotationX, in: -180...180, step: 1) {
                            Text("Rotation X")
                        } minimumValueLabel: { Text("-180") } maximumValueLabel: { Text("180") }
                    }
                    LabeledContent("Rotation Y") {
                        Slider(value: $viewModel.rotationY, in: -180...180, step: 1) {
                            Text("Rotation Y")
                        } minimumValueLabel: { Text("-180") } maximumValueLabel: { Text("180") }
                    }
                    LabeledContent("Rotation Z") {
                        Slider(value: $viewModel.rotationZ, in: -180...180, step: 1) {
                            Text("Rotation Z")
                        } minimumValueLabel: { Text("-180") } maximumValueLabel: { Text("180") }
                    }
                }

                LabeledContent("Scale:") {
                    Slider(value: $viewModel.scale, in: 0.2...3, step: 0.1) {
                        Text("Scale")
                    } minimumValueLabel: { Text("0.2") } maximumValueLabel: { Text("3") }
                }

                ColorPicker("Color", selection: $viewModel.color, supportsOpacity: false)

                Toggle("Spin", isOn: $viewModel.isSpinning)
                
                Button("Red Alert") {
                    viewModel.requestRedAlert()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    ContentView()
}
