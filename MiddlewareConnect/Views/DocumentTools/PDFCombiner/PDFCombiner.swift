/**
 * @fileoverview PDF Combiner module index
 * @module PDFCombiner
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - PDFCombiner/Views
 * - PDFCombiner/ViewModels
 * - PDFCombiner/Components
 * 
 * Exports:
 * - All PDF Combiner components
 * 
 * Notes:
 * - Re-exports all PDF Combiner components for easy imports
 * - Serves as the entry point for the PDFCombiner module
 */

// Re-export the view
@_exported import struct MiddlewareConnect.Views.DocumentTools.PDFCombiner.Views.PdfCombinerView

// Re-export the view model
@_exported import class MiddlewareConnect.Views.DocumentTools.PDFCombiner.ViewModels.PDFCombinerViewState

// Re-export the components
@_exported import struct MiddlewareConnect.Views.DocumentTools.PDFCombiner.Components.DocumentPicker
@_exported import struct MiddlewareConnect.Views.DocumentTools.PDFCombiner.Components.PDFPreviewView