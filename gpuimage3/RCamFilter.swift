import Metal


public class RCamFilter: BasicOperation {

    public var name: String?
    
    public var filterIntensity:Float = 0.0 { didSet { uniformSettings["filterIntensity"] = filterIntensity } }
    public var time:Float = 0.0 { didSet { uniformSettings["time"] = time } }
    public var audioLevel:Float = 0.0 { didSet { uniformSettings["audioLevel"] = audioLevel } }
    public var filterVariation:Float = 0.0 { didSet { uniformSettings["filterVariation"] = filterVariation } }
    
    public init(fragmentFunctionName:String, name: String) {
        super.init(fragmentFunctionName:fragmentFunctionName, numberOfInputs:1)
        
        self.name = name
        
        ({time = 0.0; filterIntensity = 0.000; audioLevel = 0.0; filterVariation = 1.0})()
    }
    
   override func internalRenderFunction(commandBuffer: MTLCommandBuffer, outputTexture: Texture) {
    time += 0.1
    super.internalRenderFunction(commandBuffer: commandBuffer, outputTexture: outputTexture)
    }
}
