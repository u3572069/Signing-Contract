pragma solidity >=0.4.22 <0.6.0;

contract Signing {
    uint public value;
    address payable public signer;
    address payable public company;
    enum State { Created, Locked, Inactive }
    State public state;

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() public payable {
        signer = msg.sender;
        value = msg.value / 2;
        require((2 * value) == msg.value, "Value has to be even.");
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyCompany() {
        require(
            msg.sender == company,
            "Only company can call this."
        );
        _;
    }

    modifier onlySigner() {
        require(
            msg.sender == signer,
            "Only Signer can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }

    event Aborted();
    event SigningConfirmed();
    event SignatureReceived();

    /// Abort the signature and reclaim the ether.
    /// Can only be called by the signer before
    /// the contract is locked.
    function abort()
        public
        onlySigner
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        signer.transfer(address(this).balance);
    }

    /// Confirm the signing as company.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmSigning
    /// is called.
    function confirmSigning()
        public
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit SigningConfirmed();
        company = msg.sender;
        state = State.Locked;
    }

    /// Confirm that you (the company) received the signature.
    /// This will release the locked ether.
    function confirmSigned()
        public
        onlyCompany
        inState(State.Locked)
    {
        emit SignatureReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;

        // NOTE: This actually allows both the company and the signer to
        // block the refund - the withdraw pattern should be used.

        company.transfer(value);
        signer.transfer(address(this).balance);
    }
}