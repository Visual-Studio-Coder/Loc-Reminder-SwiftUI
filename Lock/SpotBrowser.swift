//
//  SpotBrowser.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI

struct SpotBrowser: View {
	@Environment(\.managedObjectContext) var moc
	@FetchRequest(sortDescriptors: [
		SortDescriptor(\.nameOfLocation)
	]) var spots: FetchedResults<Spots>
	
	@State private var showingAddScreen = false
	
    var body: some View {
		
			
			NavigationView {
				List{
					ForEach(spots) {spots in
						
						NavigationLink{
							EditSpotView(spot: spots)
						} label: {
							Text(spots.nameOfLocation ?? "Untitled")
								
							
						}
						
					}
					.onDelete(perform: deleteSpots)
				}
					.navigationTitle("Browse Spots")
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							EditButton()
						}
						
						
						ToolbarItem(placement: .navigationBarTrailing) {
							Button {
								showingAddScreen.toggle()
							} label: {
								Label ("Add Spot", systemImage: "plus")
							}
							.disabled(spots.count == 20)
						}
					}
					.sheet(isPresented: $showingAddScreen) {
						AddSpotView()
					}
				
			}
			.navigationBarTitleDisplayMode(.large)
			
			
			
			
			
			
			
		
    }
	func deleteSpots(at offsets: IndexSet){
		for offset in offsets {
			let spot = spots[offset]
			moc.delete(spot)
		}
		try? moc.save()
	}
}

struct SpotBrowser_Previews: PreviewProvider {
    static var previews: some View {
        SpotBrowser()
    }
}
