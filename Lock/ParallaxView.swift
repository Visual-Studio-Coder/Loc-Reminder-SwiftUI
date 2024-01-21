//
//  ParallaxView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/3/23.
//

import SwiftUI

struct ParallaxView: View {
	/// Mark Gesture Properties
	@State var offset: CGSize = .zero
	
	
    var body: some View {
		GeometryReader{
			let size = $0.size
			let imageSize = size.width * 0.7
			VStack{
				Image("LockReminderIconClear")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: imageSize)
					.zIndex(1)
					.offset(x: offset2Angle().degrees * 3, y: offset2Angle(true).degrees * 3)
					.shadow(color: .black, radius: 10, x: 1) 
			}
			
			.frame(width: imageSize)
			.background(content: {
				ZStack {
					Rectangle()
						.fill(Color("BlueBg"))
						
				}
				.clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
				.shadow(color: .black, radius: 2)
			})
			.frame(maxWidth: .infinity,maxHeight: .infinity)
		}
		.contentShape(Rectangle())
		.rotation3DEffect(offset2Angle(true), axis: (x:1, y:0, z:0))
		.rotation3DEffect(offset2Angle(), axis: (x:0, y:1, z:0))
		.rotation3DEffect(offset2Angle(true), axis: (x:0, y:0, z:1))
		.gesture(
			DragGesture()
				.onChanged({ value in
					offset = value.translation
					
				}).onEnded({ _ in
					withAnimation(.interactiveSpring(response: 0.6, dampingFraction:  0.32, blendDuration: 0.32)){
						offset = .zero
					}
					
				})
		)
    }
	func offset2Angle(_ isVertical:Bool = false)->Angle{
		let progress = (isVertical ? offset.height : offset.width) / (isVertical ? screenSize.height : screenSize.width)
		return .init(degrees: progress * 20)
	}
	
	var screenSize: CGSize = {
		guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
		else{
			return .zero
		}
		
		return window.screen.bounds.size
	}()

}


struct ParallaxView_Previews: PreviewProvider {
    static var previews: some View {
        ParallaxView()
    }
}
