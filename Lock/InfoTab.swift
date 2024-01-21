//
//  InfoTab.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI

struct InfoTab: View {
	@Environment(\.openURL) var openURL
	var body: some View {
		
		HStack{
			VStack{
				Button(action: {openURL(URL(string: "https://www.github.com/Visual-Studio-Coder/Loc-Reminder")!)}) {
					Image("github-icon")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.padding(15)
				}
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
				Text("GitHub")
                    .padding(10)
					.scaledToFill()
			}
			
			//Divider()
			
			VStack{
				Button(action: {openURL(URL(string:"https://0mx7ody576p.typeform.com/to/AdoFf4iE")!)}) {
					Image(systemName: "ladybug.fill")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.padding(15)
				}
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
				Text("Report Bugs")
                    .padding(10)
					.scaledToFill()
			}
			
			//Divider()
			
			VStack{
				Button(action: {openURL(URL(string: "https://www.buymeacoffee.com")!)}) {
					Image("buycoffee")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.padding(15)
					
				}
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
                Text("Buy Me a Coffee")
                    .padding(10)
                    .scaledToFill()
			}
		}
		.padding()
		.frame(height: 150, alignment: .bottomLeading)
		
		
		
		
		
	}
	
	
}

struct InfoTab_Previews: PreviewProvider {
    static var previews: some View {
        InfoTab()
    }
}
