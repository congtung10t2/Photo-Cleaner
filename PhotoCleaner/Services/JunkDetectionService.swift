import Vision

enum JunkDetectionService {
    static func detect(cgImage: CGImage) -> JunkRules.Signals {
        let classificationRequest = VNClassifyImageRequest()
        let contoursRequest = VNDetectContoursRequest()
        contoursRequest.contrastAdjustment = 1.5

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([classificationRequest, contoursRequest])

        let confidence = classificationRequest.results?.first?.confidence ?? 0
        let contours = (contoursRequest.results?.first as? VNContoursObservation)?.contourCount ?? 0

        return JunkRules.Signals(
            topClassificationConfidence: confidence,
            contourCount: contours,
            luminanceStdDev: 0,
            meanLuminance: 0
        )
    }
}
