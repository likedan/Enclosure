//
//  GameBoard.swift
//  MiniWar
//
//  Created by Kedan Li on 2/20/16.
//  Copyright © 2016 TakeFive Interactive. All rights reserved.
//

import UIKit


let edgeWidth: CGFloat = 4

protocol GameBoardDelegate{
    func updateScore(playerscore:[Int])
    func setTotalRow(player:Int, row: Int)
    func showTotalRow(player:Int, row: Int)
}

class GameBoard: UIView {
    
    var game: EnclosureGame!
    
    let playerColors = [UIColor(red: 247.0/255.0, green: 149.0/255.0, blue: 157.0/255.0, alpha: 1), UIColor(red: 176.0/255.0, green: 226.0/255.0, blue: 246.0/255.0, alpha: 1)]
    
    var delegate: GameBoardDelegate?
    
    let drawAnimationTime = 0.5
    
    var tempPath = [Grid]()
    var tempPathes = [[Grid]]()
    var lineLayer = CAShapeLayer()

    var gesture: UIPanGestureRecognizer!

    var grids = [Grid]()
    var areas = [Area]()
    var edges = [Edge]()
    
    var unitWidth: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gesture = UIPanGestureRecognizer(target: self, action: "dragged:")
        self.addGestureRecognizer(gesture)
    }
    
    func buildGame(game: EnclosureGame){
        
        self.game = game
        
        for v in self.subviews{
            v.removeFromSuperview()
        }
        
        grids = [Grid]()
        edges = [Edge]()
        areas = [Area]()
        tempPath = [Grid]()
        
        self.delegate?.setTotalRow(0, row: 2)
        self.delegate?.setTotalRow(1, row: 3)
        self.delegate?.showTotalRow(1, row: 0)
        
        unitWidth = self.frame.width / CGFloat(game.boardSize)
        
        //build all nodes
        for arr in game.nodes{
            for node in arr{
                let grid = Grid(frame: CGRect(x: CGFloat(node.x) * unitWidth, y: CGFloat(node.y) * unitWidth, width: unitWidth, height: unitWidth), gameElement: node, game: self)
                grids.append(grid)
                node.view = grid
                grid.alpha = 0
                self.addSubview(grid)
                UIView.animateWithDuration(0.1, delay: 0.03 * Double(node.x + node.y), options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    grid.alpha = 1
                    }, completion: { (done) -> Void in
                        
                })
            }
        }

        //build all edges
        for fence in game.fences{
            if fence.nodes[0].x == fence.nodes[1].x{
                //vertical fence
                var upper: FenceNode!
                if fence.nodes[0].y < fence.nodes[1].y{
                    upper = fence.nodes[0]
                }else{
                    upper = fence.nodes[1]
                }
                let edge = Edge(frame: CGRect(x: upper.view.center.x - edgeWidth/2, y: upper.view.center.y + edgeWidth/2, width: edgeWidth, height: unitWidth - edgeWidth), gameElement: fence, game: self)
                self.addSubview(edge)
                fence.view = edge
                edges.append(edge)
            }else{
                //horizontal fence
                var lefter: FenceNode!
                if fence.nodes[0].x < fence.nodes[1].x{
                    lefter = fence.nodes[0]
                }else{
                    lefter = fence.nodes[1]
                }
                let edge = Edge(frame: CGRect(x: lefter.view.center.x + edgeWidth/2, y: lefter.view.center.y - edgeWidth/2, width: unitWidth - edgeWidth, height: edgeWidth), gameElement: fence, game: self)
                self.addSubview(edge)
                fence.view = edge
                edges.append(edge)
            }

        }
        
        //build all area
        for arr in game.nodes{
            for node in arr{
                if node.y < game.boardSize - 1 && node.x < game.boardSize - 1{
                    let area = Area(frame: CGRect(x: node.view.center.x + edgeWidth/2, y: node.view.center.y + edgeWidth/2, width: unitWidth - edgeWidth, height: unitWidth - edgeWidth), gameElement: game.lands[node.x][node.y], game: self)
                    game.lands[node.x][node.y].view = area
                    areas.append(area)
                    self.addSubview(area)
                }
            }
        }
        
        lineLayer.backgroundColor = UIColor.clearColor().CGColor
        self.layer.addSublayer(lineLayer)
        
        //lift nodes up
        for node in grids{
            self.bringSubviewToFront(node)
        }
        

        
    }
    
    // redraw all the element on the board according to the game
    func drawBoard(){
        for node in grids{
            node.toNormal()
        }
        for edge in edges{
            edge.update()
        }
        for area in areas{
            area.update()
        }
    }
    
    func drawPath(){
        for elem in tempPath{
            elem.enlarge()
            if elem != tempPath.last{
                let index = tempPath.indexOf(elem)
                (elem.gameElement.fences[self.tempPath[index! + 1].gameElement]?.view as! Edge).backgroundColor = self.playerColors[self.game.currentPlayer()]
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for t in touches{
            tempPath.append(getCorrespondingGrid(t.locationInView(self)))
        }
        drawPath()
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        for t in touches!{
            tempPath.removeAll()
        }
        drawBoard()
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for t in touches{
            tempPath.removeAll()
        }
        drawBoard()
    }
    
    func dragged(sender: UIPanGestureRecognizer){
        let point = sender.locationInView(self)
        let grid = getCorrespondingGrid(point)
        
        if tempPath.count == 0{
            tempPath.append(grid)
        }else{
            
            //add temp drew line
            let connectWithLast = grid.gameElement.fences.keys.contains(tempPath.last!.gameElement)
            let withinAvailableStep = tempPath.count <= game.playerFences[game.currentPlayer()]
            if !tempPath.contains(grid) && connectWithLast && withinAvailableStep && (grid.gameElement.fences[tempPath.last!.gameElement]?.player == -1 || grid.gameElement.fences[tempPath.last!.gameElement]?.player == game.currentPlayer()){
                tempPath.append(grid)
                drawPath()
            }
            
            //remove drawn line
            
            if tempPath.count > 1 && grid == tempPath[tempPath.count - 2]{
                tempPath.removeLast()
                drawBoard()
                drawPath()
            }

        if tempPath.count > 0 {
            self.delegate?.showTotalRow(game.currentPlayer(), row: game.playerFences[game.currentPlayer()] + 1 - tempPath.count)
            }
        }

        if sender.state == UIGestureRecognizerState.Cancelled || sender.state == UIGestureRecognizerState.Ended || sender.state == UIGestureRecognizerState.Failed {

            //haven't finish game
            if tempPath.count < game.playerFences[game.currentPlayer()] + 1{
                tempPath.removeAll()
                self.delegate?.showTotalRow(game.currentPlayer(), row: game.playerFences[game.currentPlayer()])
                drawBoard()
                drawPath()
            }else{
                // update current step
                var fences = [Fence]()
                for elem in tempPath{
                    if elem != tempPath.last{
                        let index = tempPath.indexOf(elem)
                        fences.append(elem.gameElement.fences[self.tempPath[index! + 1].gameElement]!)
                    }
                }
                tempPath.removeAll()
                self.delegate?.showTotalRow(game.currentPlayer(), row: 0)
                
                // move to next step
                game.updateMove(fences)
                
                drawBoard()
                self.delegate?.showTotalRow(game.currentPlayer(), row: game.playerFences[game.currentPlayer()])

            }
//
//            if (firstStep && tempPath.count == 3) || tempPath.count == 4 {


//                tempPathes = [[Grid]]()
//                for g in tempPath{
//                    checkArea(g, current: g, path: [Grid]())
//                }
//                
//                if tempPathes.count > 0{
//                    var polygons = [[CGPoint]]()
//                    for p in tempPathes{
//                        var polygon = [CGPoint]()
//                        for grid in p{
//                            polygon.append(grid.center)
//                        }
//                        polygons.append(polygon)
//                    }
//                    calculateScore(polygons)
//                    self.delegate?.updateScore(playerscore)
//                }
//                totalStep++
//            }else{
//                if self.tempPath.count > 1{
//                    for var index = 0; index < self.tempPath.count - 1; index++ {
//                        self.tempPath[index].edges[self.tempPath[index + 1]]!.backgroundColor = UIColor.clearColor()
//                        self.tempPath[index].edges[self.tempPath[index + 1]]!.user = -1
//                    }
//                }
//            }
//            tempPath = [Grid]()
            lineLayer.lineWidth = 0
        }else{
            let drawingLine = UIBezierPath()
            drawingLine.moveToPoint((tempPath.last?.center)!)
            drawingLine.addLineToPoint(point)
            drawingLine.closePath()
            lineLayer.path = drawingLine.CGPath
            lineLayer.strokeColor = playerColors[game.currentPlayer()].CGColor
            lineLayer.lineWidth = edgeWidth
        }
        
    }
    
//
//    func checkArea(start:Grid, current: Grid, var path: [Grid]){
//        if current == start && path.count >= 3{
//            path.append(current)
//            tempPathes.append(path)
//        }else{
//            path.append(current)
//            for key in (current.edges.keys){
//                if (path.count == 1 || !path.contains(key) && key != start || key == start && path.count > 2) && current.edges[key]?.user == totalStep % players.count{
//                    checkArea(start, current: key, path: path)
//                }
//            }
//        }
//
//    }
    
    
//    func calculateScore(polygons: [[CGPoint]]){
//        for x in areas{
//            for y in x{
//                for p in polygons{
//                    if containPolygon(p, test: y.center) && y.user == -1{
//                        y.user = totalStep % players.count
//                        y.backgroundColor = players[totalStep % players.count]
//                        UIView.animateWithDuration(0.3, animations: { () -> Void in
//                            y.alpha = 0.65
//                        })
//                        playerscore[totalStep % players.count]++
////                        animateScore(y, score: 1, player: totalStep % players.count)
//                        
//                    }
//                }
//            }
//        }
//    }

//    func animateScore(area: Area, score: Int, player: Int){
//        var lab = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        lab.center = area.center
//        lab.textColor = players[player]
//        lab.alpha = 1
//        lab.textAlignment = NSTextAlignment.Center
//        lab.font = UIFont(name: "Avenir-Light", size: 20.0)
//        lab.text = "+\(score)"
//        self.addSubview(lab)
//        
////        UIView.animateWithDuration(0.3, animations: { () -> Void in
////            lab.alpha = 0
////            lab.frame =
////            }) { (haha) -> Void in
////                
////        }
//    }
    
    func getCorrespondingGrid(p: CGPoint)->Grid{
        var x = Int(p.x/unitWidth)
        if x < 0{
            x = 0
        }else if x >= game.boardSize{
            x = game.boardSize - 1
        }
        var y = Int(p.y/unitWidth)
        if y < 0{
            y = 0
        }else if y >= game.boardSize{
            y = game.boardSize - 1
        }
        return game.nodes[x][y].view as! Grid
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gesture = UIPanGestureRecognizer(target: self, action: "dragged:")
        self.addGestureRecognizer(gesture)
    }
    
    func containPolygon(polygon: [CGPoint], test: CGPoint) -> Bool {
        if polygon.count <= 1 {
            return false //or if first point = test -> return true
        }
        
        let p = UIBezierPath()
        let firstPoint = polygon[0] as CGPoint
        
        p.moveToPoint(firstPoint)
        
        for index in 1...polygon.count-1 {
            p.addLineToPoint(polygon[index] as CGPoint)
        }
        
        p.closePath()
        
        return p.containsPoint(test)
    }
    
}

class Grid: UIView {
    
    let gameElement: FenceNode
    let game: GameBoard

    var centerGrid: UIView!
    init(frame: CGRect, gameElement: FenceNode, game: GameBoard) {
        self.gameElement = gameElement
        self.game = game
        super.init(frame: frame)
        centerGrid = UIView(frame: CGRect(x: 0, y: 0, width: edgeWidth, height: edgeWidth))
        centerGrid.backgroundColor = UIColor.blackColor()
        self.addSubview(centerGrid)
        centerGrid.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.width / 2)
        self.userInteractionEnabled = false
    }

    func enlarge(){
        self.transform = CGAffineTransformMakeScale(2, 2)
    }
    
    func toNormal(){
        self.transform = CGAffineTransformMakeScale(1, 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Edge: UIView {
    
    let gameElement: Fence
    let game: GameBoard

    init(frame: CGRect, gameElement: Fence, game: GameBoard) {
        self.gameElement = gameElement
        self.game = game
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(){
        var selectedColor = UIColor.clearColor()
        if gameElement.player != -1{
            selectedColor = game.playerColors[gameElement.player]
        }
        UIView.animateWithDuration(game.drawAnimationTime) { () -> Void in
            self.backgroundColor = selectedColor
        }
    }
    
}

class Area: UIView {

    let game: GameBoard
    let gameElement: Land
    
    init(frame: CGRect, gameElement: Land, game: GameBoard) {
        self.gameElement = gameElement
        self.game = game
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.alpha = 0.8

    }
    
    func update(){
        var selectedColor = UIColor.whiteColor()
        var a:CGFloat = 0.8
        if gameElement.player != -1{
            selectedColor = game.playerColors[gameElement.player]
            a = 0.6
        }
        UIView.animateWithDuration(0.5) { () -> Void in
            self.backgroundColor = selectedColor
            self.alpha = a
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Rows: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let length:CGFloat = 60
    var color: UIColor!
    var views = [UIView]()
    
    func changeBarNum(num : Int){
        
        for v in views{
            v.removeFromSuperview()
        }
        views = [UIView]()
        let startIndex: CGFloat = (self.frame.width - (length * CGFloat(num) + 10 * CGFloat(num - 1))) / 2
        for var index = 0; index < num; index++ {
            let v = UIView(frame: CGRect(x: startIndex + (10.0 + length) * CGFloat(index), y: 0, width: length, height: 6))
            v.backgroundColor = color
            views.append(v)
            self.addSubview(v)
        }
    }
    
    func displayNum(num : Int){
        for var index = 0; index < views.count; index++ {
            if index < num{
                views[index].alpha = 1
            }else{
                views[index].alpha = 0
            }
        }
    }
    
}

