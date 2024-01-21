//
//  threeDimensionalButton.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 4/25/23.
//

import SwiftUI

struct threeDimensionalButton: ButtonStyle{
	
	let lateralGradient:LinearGradient
	let flatGradient:LinearGradient

	
	
    func makeBody(configuration: Configuration) -> some View {
        
        
        ZStack{
            
            
            let offset: CGFloat = 8
            let cornerRadius: CGFloat = 22
            
			
   
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(lateralGradient)
                .offset(y: offset)
                

            
            RoundedRectangle(cornerRadius: cornerRadius)
                
                .fill(flatGradient)
                
                
                
        
                
                .offset(y: configuration.isPressed ? offset : 0)
            configuration.label
                
                .font(.largeTitle)
                .foregroundColor(Color(red: 0.004, green: 0.157, blue: 0.545))
                .bold()
                .foregroundColor(.blue)
                .offset(y: configuration.isPressed ? offset : 0)
                .animation(.easeInOut, value: 1)
        }
        .compositingGroup()
        //.shadow(radius: 22, y: 4)
        
    }
    
}


struct threeDimensionalButton_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }){
            Text("asdasjdasd")
        }
        .foregroundColor(.white)
        .frame(width: 332, height: 68)
		.buttonStyle(threeDimensionalButton(lateralGradient: LinearGradient(
			gradient: Gradient(stops: [
				.init(color: .init(red: 0.3, green: 0.5, blue: 0.9),
					  location: 0.00001),
				.init(color: .init(red: 0.484, green: 0.7, blue: 1),
					  location: 0.1),
				.init(color: .init(red: 0.484, green: 0.7, blue: 1),
					  location: 0.9),
				.init(color: .init(red: 0.3, green: 0.5, blue: 0.9),
					  location: 0.99999)
			]),
			startPoint: .leading,
			endPoint: .trailing
		), flatGradient: LinearGradient(gradient: Gradient(colors: [.white,.init(red: 0.584, green: 0.749, blue: 1)]), startPoint: .top, endPoint: .bottom)))
    }
}
