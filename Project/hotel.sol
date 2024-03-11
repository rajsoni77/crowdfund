// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Hostel{

    address payable tenant;
    address payable landlord;

    uint public no_of_rooms = 0;
    uint public no_of_agreement = 0;
    uint public no_of_rent = 0;

    struct Room{
        uint roomid;
        uint agreementid;
        string roomname;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord; 
        address payable currentTenant; 
    }

    mapping(uint => Room) public Room_by_No;

    struct RoomAgreement{
        uint roomid;
        uint agreementid;
        string Roomname;
        string RoomAddresss;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
       uint lockInPeriod;
        address payable tenantAddress; 
        address payable landlordAddress; 
    }

     mapping(uint => RoomAgreement) public RoomAgreement_by_No;

        struct Rent{
        uint rentno;
        uint roomid;
        uint agreementid;
        string Roomname;
        string RoomAddresss;
        uint rent_per_month;
        uint timestamp;
        address payable tenantAddress; 
        address payable landlordAddress;
}

mapping(uint=> Rent) public Rent_by_no;

modifier onlyLandlord(uint _index){
    require(msg.sender == Room_by_No[_index].landlord, "Only Landlord can access this");
    _;
}

modifier notLandlord(uint _index){
    require(msg.sender != Room_by_No[_index].landlord, "Only Tenant can access this");
    _;
}

modifier OnlyWhileVacant(uint _index){
    require(Room_by_No[_index].vacant ==true, "Room is currently Occupied.");
    _;
}

modifier enoughRent(uint _index){
    require(msg.value >= uint(Room_by_No[_index].rent_per_month), "Not enough Ether in your wallet ");
    _;
}

modifier enoughAgreement(uint _index){
    require(msg.value >= uint(uint(Room_by_No[_index].rent_per_month) + uint(Room_by_No[_index].securityDeposit)), "Enough agreement");
    _;
}

modifier sameTenant(uint _index){
    require(msg.sender == Room_by_No[_index].currentTenant, "No Previous agreement found with you");
   _;
}

modifier AgreementTimeLeft(uint _index){
uint _AgreementNo = RoomAgreement_by_No[Room_by_No[_index].agreementid].agreementid;
    uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockInPeriod;
    require(now < time, "Agreement already Ended");
    _;
}

modifier AgreementTimeUp(uint _index){
    uint _AgreementNo = Room_by_No[_index].agreementid;
    uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockInPeriod;
    require(now > time, "Time is left for contract to end");
    _;
}

modifier RentTimesUp(uint _index){
    uint time = Room_by_No[_index].timestamp + 30 days;
    require(now >= time, "Time left to pay Rent");
    _;
}

function addRoom(string memory _roomname, string memory _roomaddress, uint _rentcost, uint _securityDeposit) public {
    require(msg.sender != address(0));
    no_of_rooms ++;
    bool _vacancy =true;
    Room_by_No[no_of_rooms]= Room(no_of_rooms,0, _roomname, _rentcost, _securityDeposit, 0, _vacancy, msg.sender, address(0));
}

function signAgreement(uint _index) public payable notLandlord(_index) enoughAgreement(_index) onlyLandlord(_index){
require(msg.sender != address(0));
address payable _landlord =Room_by_No[_index].landlord;
uint totalfee =  Room_by_No[_index].rent_per_month + Room_by_No[_index].securityDeposit;
_landlord.transfer(totalfee);
no_of_agreement++;
Room_by_No[_index].currentTenant = msg.sender;
Room_by_No[_index].vacant =false;
Room_by_No[_index].timestamp =block.timestamp;
Room_by_No[_index].agreementid = no_of_agreement;
RoomAgreement_by_No[no_of_agreement]=RoomAgreement(_index, no_of_agreement, Room_by_No[_index].roomname);
no_of_rent++;
Rent_by_no[no_of_rent] = Rent(no_of_rent,_index,no_of_agreement,Room_by_No[_index].roomname,Room_by_No[_index]);}

function payRent(uint _index) public payable sameTenant(_index) RentTimesUp(_index) enoughRent(_index) {
    require(msg.sender != address(0));
    address payable _landlord = Room_by_No[_index].landlord;
    uint _rent = Room_by_No[_index].rent_per_month;
    _landlord.transfer(_rent);
    Room_by_No[_index].currentTenant=msg.sender;
     Room_by_No[_index].vacant = false;
     no_of_rent++;
     Rent_by_no[no_of_rent] = Rent(no_of_rent,_index, Room_by_No[_index].agreementid,Room_by_No[_index].roomname);
}

function agreementCompleted(uint _index) public payable onlyLandlord(_index) AgreementTimeUp(_index){
    require(msg.sender != address(0));
    require(Room_by_No[_index].vacant== false, " Room is currently occupied");
    Room_by_No[_index].vacant = true;
    address payable _Tenant = Room_by_No[_index]._currentTenant;
    uint _securitydeposit = Room_by_No[_index].securityDeposit;
    _Tenant.transfer(_securitydeposit);
}
   function agreementTerminated(uint _index) public onlyLandlord(_index) AgreementTimeLeft(_index) {
   require(msg.sender != address(0));
   Room_by_No[_index].vacant = true;
   }
}



