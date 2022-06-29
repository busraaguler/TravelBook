//
//  ViewController.swift
//  TravelBook
//
//  Created by busraguler on 10.06.2022.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController , MKMapViewDelegate, CLLocationManagerDelegate{

    
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var MapView: MKMapView!
    var locationManager = CLLocationManager()
    
    var chosenLatitude = Double()
    var chosenLongitude = Double ()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //kullanıcı konum bilgisine izin verdiğinde
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3  // 3 sn basılı tutarsa
        MapView.addGestureRecognizer(gestureRecognizer) //mapView'e  gestureRecognizer özelliği eklendi
        
        if selectedTitle != ""{
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let idString = selectedTitleId!.uuidString  //id'yi string'e çeviridi
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            fetchRequest.predicate = NSPredicate(format: "id = %@",  idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                 let results = try context.fetch(fetchRequest)
                 if results.count>0 {
                    for result in results  as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subTitle") as? String{
                                annotationSubTitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubTitle
                                        let coordinate = CLLocationCoordinate2D (latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        MapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubTitle
                                        
                                        
                                        locationManager.stopUpdatingLocation() //Lokasyonun güncellenmesi istenmiyor. Location durdur.
                                        let span  = MKCoordinateSpan (latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion (center: coordinate, span: span)
                                        
                                        MapView.setRegion(region, animated: true)
                                    }
                                }
                                
                            }
                            
                        }
                    }
                }
                
                
            }catch{
                print("error")
            }
        }else{
            //boşsa
            
        }
        
        
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){ //input almanın nedeni gestureRecognizer'ın kendi metodlarına ulaşabilmek
        
        //pin oluşturmak için tıklanılan yerin koordinatları gerekli.
        
        if gestureRecognizer.state == .began { //dokunma işlemi gerçekleştiyse
            let touchPoint = gestureRecognizer.location(in: self.MapView)
            let touchedCoordinates = self.MapView.convert(touchPoint, toCoordinateFrom: self.MapView)//dokunulan noktayı koordinatlara çevirdi.
            
            
            chosenLongitude = touchedCoordinates.longitude
            chosenLatitude = touchedCoordinates.latitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.MapView.addAnnotation(annotation)
            
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == ""{ //sadece boş ise harita değişsin
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //kullanıcı konumunun enlem ve boylam bilgilerini alır
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //zoom miktarı
        let region = MKCoordinateRegion(center: location, span: span) //merkezi kendi locasayon seçildi. zoom oranı belirlenen span
        MapView.setRegion(region, animated: true)
        }else{
            //
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reusedId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusedId)  as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedId) //MKpinAnnotation : Harita üzerinde bir iğne görüntüsü görüntüleyen bir açıklama görünümü.
            pinView?.canShowCallout = true //Bir baloncukla birlikte ekstra bilgi gösterdiğimiz yer.
            pinView?.tintColor = UIColor.green // pin rengi
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) //Detayların görünebileceği bir button
            pinView?.rightCalloutAccessoryView = button // caShowCallout içine sağ üste bişgi butonu
            
            
        }
        else{
            pinView?.annotation = annotation // boş değilse daha önceden oluşturulduysa annocation ı göster.
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {  //pin oluşturulmuşsa
             //navigasyonu açabilmemiz için mapItem oluşturmamız gerekiyor.
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count>0  {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] // araba ile //hangi modda açılacak navigasyon
                        item.openInMaps(launchOptions: launchOptions) //navigasyonu arabaya göre açıcak
                        
                    }
                }
            }
            
        }
    }
    
    
    
    
    
    
    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subTitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("başarılı")
        }catch{
            print("hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("New Place"), object: nil) //App'e mesaj gönderir.yeni veri geldiğinde
        navigationController?.popViewController(animated: true)  //diğer view controller'a gitmemizi sağlamaktadır.
        
        
    }
    
    
    

}

